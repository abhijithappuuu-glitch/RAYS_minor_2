import 'package:hive_ce/hive_ce.dart';

part 'stress_record.g.dart';

/// Hive type adapter for persisted stress score records
@HiveType(typeId: 0)
class StressRecord extends HiveObject {
  @HiveField(0)
  late int stressScore;

  @HiveField(1)
  late String riskLevel;

  @HiveField(2)
  late double confidence;

  @HiveField(3)
  late String breakdownJson; // JSON-encoded Map<String, dynamic>

  @HiveField(4)
  late String encryptedPayload; // AES-256-GCM encrypted full JSON

  @HiveField(5)
  late DateTime timestamp;

  @HiveField(6)
  late bool synced;
}
