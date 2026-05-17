import 'package:rakshak_ai/domain/entities/stress_score.dart';

/// Abstract repository for stress score persistence
abstract class StressRepository {
  Future<void> saveStressScore(StressScore score);
  Future<List<StressScore>> getStressHistory({int days = 7});
  Future<StressScore?> getLatestStressScore();
  Future<void> syncToServer();
}
