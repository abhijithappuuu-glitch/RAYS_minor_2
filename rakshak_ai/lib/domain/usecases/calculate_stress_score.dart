import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/repositories/stress_repository.dart';

/// Use case: Calculate and persist a stress score from collected data
class CalculateStressScore {
  final StressRepository _repository;

  CalculateStressScore(this._repository);

  Future<void> execute(StressScore score) async {
    await _repository.saveStressScore(score);
  }

  Future<List<StressScore>> getHistory({int days = 7}) async {
    return await _repository.getStressHistory(days: days);
  }

  Future<StressScore?> getLatest() async {
    return await _repository.getLatestStressScore();
  }
}
