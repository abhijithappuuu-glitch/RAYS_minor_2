import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';
import 'package:rakshak_ai/domain/usecases/calculate_stress_score.dart';
import 'package:rakshak_ai/domain/usecases/fetch_usage_stats.dart';
import 'package:rakshak_ai/domain/usecases/predict_stress_ml.dart';

/// Current stress score state
final stressScoreProvider =
    NotifierProvider<StressScoreNotifier, AsyncValue<StressScore?>>(
  StressScoreNotifier.new,
);

/// Stress history for charts
final stressHistoryProvider =
    FutureProvider.family<List<StressScore>, int>((ref, days) async {
  final useCase = getIt<CalculateStressScore>();
  return await useCase.getHistory(days: days);
});

/// User behavior data
final userBehaviorProvider =
    FutureProvider<UserBehavior>((ref) async {
  final useCase = getIt<FetchUsageStats>();
  return await useCase.execute();
});

class StressScoreNotifier extends Notifier<AsyncValue<StressScore?>> {
  @override
  AsyncValue<StressScore?> build() => const AsyncValue.data(null);

  Future<void> calculateCurrentStress() async {
    state = const AsyncValue.loading();
    try {
      // Fetch usage data
      final fetchUsage = getIt<FetchUsageStats>();
      final behavior = await fetchUsage.execute();

      // Run ML prediction
      final predict = getIt<PredictStressML>();
      final score = predict.execute(behavior: behavior);

      // Persist
      final save = getIt<CalculateStressScore>();
      await save.execute(score);

      state = AsyncValue.data(score);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
