import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:rakshak_ai/core/error/error_handler.dart';

const String _taskName = 'rakshak_monitoring_task';
const String _usageStatsChannel = 'rakshak.ai/usage_stats';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background task is disabled for demo.
      // Data collection only — no scoring or notifications.
      await _collectDataQuietly();
      return true;
    } catch (e) {
      ErrorHandler.handleError(e);
      return false;
    }
  });
}

/// Quietly collects usage data and caches it for later.
/// Does NOT score, does NOT trigger notifications.
Future<void> _collectDataQuietly() async {
  try {
    const platform = MethodChannel(_usageStatsChannel);
    final result = await platform.invokeMethod<Map>('getUsageStats');
    // Data is collected but intentionally not processed.
    // The real-time "Scan" button in the app handles prediction via backend.
    if (result != null) {
      await platform.invokeMethod('cacheUsageData', {
        'social_minutes': result['social_minutes'] ?? 0,
        'late_night_usage': result['late_night_usage'] ?? false,
        'doom_scroll_flag': result['doom_scroll_flag'] ?? false,
        'pickup_count': result['pickup_count'] ?? 0,
        'total_screen_minutes': result['total_screen_minutes'] ?? 0,
        'collected_at': DateTime.now().toIso8601String(),
      });
    }
  } catch (_) {
    // Collection failure is non-fatal
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
