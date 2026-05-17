import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak_ai/features/background_monitoring/background_task_manager.dart';

class AdaptiveScheduler {
  static const String _taskName = 'rakshak_monitoring_task';
  static const String _normalFrequency = 'NORMAL';
  static const String _highRiskFrequency = 'HIGH_RISK';
  static const String _ghostMode = 'GHOST';
  
  final BackgroundTaskManager _taskManager = BackgroundTaskManager();

  Future<void> initialize() async {
    await _taskManager.initialize();
  }
  
  Future<void> scheduleMonitoring(String mode) async {
    await _taskManager.cancelAll();
    
    switch (mode) {
      case _normalFrequency:
        await _scheduleNormalMode();
        break;
      case _highRiskFrequency:
        await _scheduleHighRiskMode();
        break;
      case _ghostMode:
        // No scheduling in ghost mode
        break;
    }
  }
  
  Future<void> _scheduleNormalMode() async {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 4),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
  
  Future<void> _scheduleHighRiskMode() async {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
  
  Future<void> saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_timestamp');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}
