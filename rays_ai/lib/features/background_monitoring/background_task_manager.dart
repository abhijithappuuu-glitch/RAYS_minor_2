import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:rakshak_ai/core/error/error_handler.dart';
import 'package:rakshak_ai/core/services/notification_service.dart';
import 'package:rakshak_ai/features/ml_engine/on_device_ml.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';

const String _taskName = 'rakshak_monitoring_task';
const String _usageStatsChannel = 'rakshak.ai/usage_stats';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Execute background data collection
      await _collectAndAnalyzeData();
      return true;
    } catch (e) {
      ErrorHandler.handleError(e);
      return false;
    }
  });
}

Future<void> _collectAndAnalyzeData() async {
  // ── Collect usage stats via native platform channel ──
  Map<String, dynamic> usageData;
  try {
    const platform = MethodChannel(_usageStatsChannel);
    final result = await platform.invokeMethod<Map>('getUsageStats');
    usageData = {
      'social_minutes': result?['social_minutes'] ?? 0,
      'late_night_usage': result?['late_night_usage'] ?? false,
      'doom_scroll_flag': result?['doom_scroll_flag'] ?? false,
      'pickup_count': result?['pickup_count'] ?? 0,
      'total_screen_minutes': result?['total_screen_minutes'] ?? 0,
    };
  } catch (e) {
    // Graceful degradation if platform channel fails
    usageData = {
      'social_minutes': 0,
      'late_night_usage': false,
      'doom_scroll_flag': false,
      'pickup_count': 0,
      'total_screen_minutes': 0,
    };
  }

  // ── Collect health data (uses defaults if unavailable in bg) ──
  // Note: Health Connect reads require foreground; use last-cached values
  final healthData = <String, dynamic>{
    'sleep_minutes': 420, // Will be updated when foregrounded
    'exercise_minutes': 0,
  };

  // ── Calculate stress using on-device ML ──
  final stressResult = OnDeviceMLEngine.calculateStressScore(
    socialMinutes: usageData['social_minutes'] as int,
    lateNightUsage: usageData['late_night_usage'] as bool,
    sleepMinutes: healthData['sleep_minutes'] as int,
    doomScrollFlag: usageData['doom_scroll_flag'] as bool,
    pickupCount: usageData['pickup_count'] as int,
    exerciseMinutes: healthData['exercise_minutes'] as int,
  );

  final currentScore = StressScore(
    score: stressResult['stress_score'] as int,
    riskLevel: stressResult['risk_level'] as String,
    confidence: stressResult['confidence'] as double,
    breakdown: stressResult,
    timestamp: DateTime.now(),
  );

  // ── Trigger smart notifications ──
  await NotificationService().processStressUpdate(
    currentScore,
    null, // Previous score loaded from DB when available
    {
      'social_minutes': usageData['social_minutes'],
      'late_night_usage': usageData['late_night_usage'],
      'sleep_minutes': healthData['sleep_minutes'],
      'doom_scroll_flag': usageData['doom_scroll_flag'],
      'pickup_count': usageData['pickup_count'],
      'exercise_minutes': healthData['exercise_minutes'],
    },
  );

  // Note: Isar DB write happens via StressRepositoryImpl when DI is available
  // In isolated bg task, we use platform channel to store via native side
  try {
    const platform = MethodChannel(_usageStatsChannel);
    await platform.invokeMethod('cacheStressScore', {
      'score': currentScore.score,
      'risk_level': currentScore.riskLevel,
      'timestamp': currentScore.timestamp.toIso8601String(),
    });
  } catch (_) {
    // Caching failure is non-fatal
  }
}

class BackgroundTaskManager {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> registerPeriodicTask({
    Duration frequency = const Duration(hours: 4),
    bool requiresBatteryNotLow = true,
    bool requiresNetwork = true,
  }) async {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: frequency,
      constraints: Constraints(
        networkType:
            requiresNetwork ? NetworkType.connected : NetworkType.notRequired,
        requiresBatteryNotLow: requiresBatteryNotLow,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  Future<void> runOneOff() async {
    await Workmanager().registerOneOffTask(
      '${_taskName}_oneoff',
      _taskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
