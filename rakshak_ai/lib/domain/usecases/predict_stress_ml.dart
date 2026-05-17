import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';
import 'package:rakshak_ai/features/ml_engine/on_device_ml.dart';

/// Use case: Run on-device ML prediction to produce a StressScore
class PredictStressML {
  StressScore execute({
    required UserBehavior behavior,
    int? sleepMinutes,
    int? exerciseMinutes,
    int? restingHeartRate,
  }) {
    final result = OnDeviceMLEngine.calculateStressScore(
      socialMinutes: behavior.socialMinutes,
      lateNightUsage: behavior.lateNightUsage,
      sleepMinutes: sleepMinutes ?? 0,
      doomScrollFlag: behavior.doomScrollFlag,
      pickupCount: behavior.pickupCount,
      exerciseMinutes: exerciseMinutes,
      restingHeartRate: restingHeartRate,
    );

    return StressScore(
      score: result['stress_score'] as int,
      riskLevel: result['risk_level'] as String,
      confidence: result['confidence'] as double,
      breakdown: result['breakdown'] as Map<String, dynamic>,
      timestamp: DateTime.now(),
    );
  }
}
