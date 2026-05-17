import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rakshak_ai/data/datasources/local/collections/stress_record.dart';
import 'package:rakshak_ai/data/datasources/local/collections/usage_record.dart';
import 'package:rakshak_ai/data/datasources/local/collections/health_record.dart';

/// Local Hive database initialization and access
class IsarDatabase {
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(StressRecordAdapter());
    Hive.registerAdapter(UsageRecordAdapter());
    Hive.registerAdapter(HealthRecordAdapter());
    _initialized = true;
  }

  Future<Box<StressRecord>> get stressBox async {
    if (!Hive.isBoxOpen('stress_records')) {
      return await Hive.openBox<StressRecord>('stress_records');
    }
    return Hive.box<StressRecord>('stress_records');
  }

  Future<Box<UsageRecord>> get usageBox async {
    if (!Hive.isBoxOpen('usage_records')) {
      return await Hive.openBox<UsageRecord>('usage_records');
    }
    return Hive.box<UsageRecord>('usage_records');
  }

  Future<Box<HealthRecord>> get healthBox async {
    if (!Hive.isBoxOpen('health_records')) {
      return await Hive.openBox<HealthRecord>('health_records');
    }
    return Hive.box<HealthRecord>('health_records');
  }

  Future<void> close() async {
    await Hive.close();
  }

  Future<void> clearAll() async {
    final stress = await stressBox;
    final usage = await usageBox;
    final health = await healthBox;
    await stress.clear();
    await usage.clear();
    await health.clear();
  }

  /// Get count of unsynced stress records
  Future<int> getUnsyncedCount() async {
    final box = await stressBox;
    return box.values.where((r) => !r.synced).length;
  }

  /// Get total record count
  Future<int> getTotalRecordCount() async {
    final box = await stressBox;
    return box.length;
  }
}
