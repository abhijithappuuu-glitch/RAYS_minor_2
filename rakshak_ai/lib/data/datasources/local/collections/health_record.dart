import 'package:hive_ce/hive_ce.dart';

part 'health_record.g.dart';

/// Hive type adapter for persisted health data
@HiveType(typeId: 2)
class HealthRecord extends HiveObject {
  @HiveField(0)
  int? sleepMinutes;

  @HiveField(1)
  int? exerciseMinutes;

  @HiveField(2)
  int? restingHeartRate;

  @HiveField(3)
  int? steps;

  @HiveField(4)
  late DateTime collectedAt;
}
