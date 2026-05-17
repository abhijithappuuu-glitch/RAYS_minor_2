import 'dart:convert';
import 'package:rakshak_ai/core/network/network_service.dart';
import 'package:rakshak_ai/core/security/encryption_service.dart';
import 'package:rakshak_ai/data/datasources/local/isar_database.dart';
import 'package:rakshak_ai/data/datasources/local/collections/stress_record.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/repositories/stress_repository.dart';

class StressRepositoryImpl implements StressRepository {
  final IsarDatabase database;
  final NetworkService networkService;
  final EncryptionService encryptionService;

  StressRepositoryImpl({
    required this.database,
    required this.networkService,
    required this.encryptionService,
  });

  @override
  Future<void> saveStressScore(StressScore score) async {
    final box = await database.stressBox;

    // Encrypt full payload for at-rest security
    final payload = jsonEncode({
      'score': score.score,
      'risk_level': score.riskLevel,
      'confidence': score.confidence,
      'breakdown': score.breakdown,
      'timestamp': score.timestamp.toIso8601String(),
    });
    final encrypted = await encryptionService.encrypt(payload);

    final record = StressRecord()
      ..stressScore = score.score
      ..riskLevel = score.riskLevel
      ..confidence = score.confidence
      ..breakdownJson = jsonEncode(score.breakdown)
      ..encryptedPayload = encrypted
      ..timestamp = score.timestamp
      ..synced = false;

    await box.add(record);
  }

  @override
  Future<List<StressScore>> getStressHistory({int days = 7}) async {
    final box = await database.stressBox;
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final records = box.values
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return records.map((r) {
      Map<String, dynamic> breakdown = {};
      try {
        breakdown = jsonDecode(r.breakdownJson) as Map<String, dynamic>;
      } catch (_) {}

      return StressScore(
        score: r.stressScore,
        riskLevel: r.riskLevel,
        confidence: r.confidence,
        breakdown: breakdown,
        timestamp: r.timestamp,
      );
    }).toList();
  }

  @override
  Future<StressScore?> getLatestStressScore() async {
    final box = await database.stressBox;
    if (box.isEmpty) return null;

    final records = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final record = records.first;

    Map<String, dynamic> breakdown = {};
    try {
      breakdown = jsonDecode(record.breakdownJson) as Map<String, dynamic>;
    } catch (_) {}

    return StressScore(
      score: record.stressScore,
      riskLevel: record.riskLevel,
      confidence: record.confidence,
      breakdown: breakdown,
      timestamp: record.timestamp,
    );
  }

  @override
  Future<void> syncToServer() async {
    final box = await database.stressBox;
    final unsyncedRecords = box.values.where((r) => !r.synced).toList();

    if (unsyncedRecords.isEmpty) return;

    try {
      final payloads = unsyncedRecords.map((r) => {
            'score': r.stressScore,
            'risk_level': r.riskLevel,
            'confidence': r.confidence,
            'timestamp': r.timestamp.toIso8601String(),
            'encrypted_payload': r.encryptedPayload,
          }).toList();

      await networkService.post(
        '/stress/sync',
        data: {'records': payloads},
      );

      // Mark synced
      for (final record in unsyncedRecords) {
        record.synced = true;
        await record.save();
      }
    } catch (e) {
      // Sync failure is non-fatal; will retry next cycle
    }
  }
}
