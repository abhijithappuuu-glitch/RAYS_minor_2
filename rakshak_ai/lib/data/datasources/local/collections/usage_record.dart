import 'package:hive_ce/hive_ce.dart';

part 'usage_record.g.dart';

/// Hive type adapter for persisted usage statistics
@HiveType(typeId: 1)
class UsageRecord extends HiveObject {
  @HiveField(0)
  late int socialMinutes;

  @HiveField(1)
  late int pickupCount;

  @HiveField(2)
  late bool lateNightUsage;

  @HiveField(3)
  late bool doomScrollFlag;

  @HiveField(4)
  late int totalScreenMinutes;

  @HiveField(5)
  late DateTime collectedAt;
}
