import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';

/// Use case: Predict stress — DEPRECATED
///
/// On-device ML scoring has been removed. All predictions are now handled
/// by the Python backend via StressAnalysisEngine.analyzeStress().
/// This class is kept as a stub so DI registration doesn't crash.
class PredictStressML {
  StressScore execute({
    required UserBehavior behavior,
    int? sleepMinutes,
    int? exerciseMinutes,
    int? restingHeartRate,
  }) {
    // Returns a neutral placeholder — not used in the demo flow.
    return StressScore(
      score: 0,
      riskLevel: 'low',
      confidence: 0.0,
      breakdown: const {},
      timestamp: DateTime.now(),
    );
  }
}
