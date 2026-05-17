import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combined stress analysis engine that merges:
///  - Questionnaire score (PSS-4 based)
///  - Mobile usage patterns
///  - Fitness / Google Fit data
///  - (optionally) ML backend prediction
///
/// Produces a unified stress score 0–100 and risk level.
class StressAnalysis {
  final int overallScore;       // 0-100
  final String riskLevel;       // Low, Medium, High
  final int questionnaireScore; // 0-100, -1 if not taken
  final int usageScore;         // 0-100
  final int fitnessScore;       // 0-100

  final String primaryFactor;
  final List<String> factors;

  /// Set when the backend ML prediction was successfully applied.
  final int? mlScore;
  final double? mlConfidence;
  /// True when [mlScore] overrides the local [overallScore].
  final bool mlEnhanced;

  StressAnalysis({
    required this.overallScore,
    required this.riskLevel,
    required this.questionnaireScore,
    required this.usageScore,
    required this.fitnessScore,
    required this.primaryFactor,
    required this.factors,
    this.mlScore,
    this.mlConfidence,
    this.mlEnhanced = false,
  });

  static String computeRiskLevel(int score) {
    if (score <= 35) return 'Low';
    if (score <= 65) return 'Medium';
    return 'High';
  }

  /// Return a copy where the backend ML prediction replaces the overall score.
  StressAnalysis copyWithMl({
    required int mlScore,
    required double mlConfidence,
  }) {
    return StressAnalysis(
      overallScore: mlScore,
      riskLevel: computeRiskLevel(mlScore),
      questionnaireScore: questionnaireScore,
      usageScore: usageScore,
      fitnessScore: fitnessScore,
      primaryFactor: primaryFactor,
      factors: factors,
      mlScore: mlScore,
      mlConfidence: mlConfidence,
      mlEnhanced: true,
    );
  }
}

class StressAnalysisEngine {
  /// Weights for each component
  static const double wQuestionnaire = 0.40;
  static const double wUsage = 0.30;
  static const double wFitness = 0.30;

  /// Compute mobile-usage based stress score (0-100)
  /// Higher screen time / social media / late-night → higher score
  static int computeUsageScore({
    required double screenTimeHours,
    required double socialMediaHours,
    required int unlocks,
    required bool lateNightUsage,
  }) {
    double s = 0;

    // Screen time: 0-3h = low, 3-6h = medium, >6h = high
    if (screenTimeHours > 8) {
      s += 30;
    } else if (screenTimeHours > 6) {
      s += 22;
    } else if (screenTimeHours > 3) {
      s += 12;
    } else {
      s += 4;
    }

    // Social media: >2h is concerning
    if (socialMediaHours > 3) {
      s += 25;
    } else if (socialMediaHours > 2) {
      s += 18;
    } else if (socialMediaHours > 1) {
      s += 10;
    } else {
      s += 3;
    }

    // Unlocks: >80 is excessive
    if (unlocks > 100) {
      s += 25;
    } else if (unlocks > 60) {
      s += 18;
    } else if (unlocks > 30) {
      s += 10;
    } else {
      s += 3;
    }

    // Late night usage penalty
    if (lateNightUsage) s += 20;

    return s.clamp(0, 100).round();
  }

  /// Compute fitness-based stress score (0-100).
  /// INVERSE: better fitness → lower stress.
  static int computeFitnessScore({
    required int steps,
    required double sleepHours,
    required int exerciseMinutes,
    required int heartRate,
  }) {
    double s = 0;

    // Steps: <3000 = high stress, >8000 = low stress
    if (steps < 2000) {
      s += 25;
    } else if (steps < 5000) {
      s += 18;
    } else if (steps < 8000) {
      s += 10;
    } else {
      s += 3;
    }

    // Sleep: <5h = high stress, >7h = low
    if (sleepHours < 4) {
      s += 30;
    } else if (sleepHours < 6) {
      s += 20;
    } else if (sleepHours < 7) {
      s += 10;
    } else {
      s += 3;
    }

    // Exercise: <10 min = high stress, >30 min = low
    if (exerciseMinutes < 10) {
      s += 20;
    } else if (exerciseMinutes < 20) {
      s += 12;
    } else if (exerciseMinutes < 30) {
      s += 6;
    } else {
      s += 2;
    }

    // Heart rate: >100 elevated stress
    if (heartRate > 100) {
      s += 25;
    } else if (heartRate > 85) {
      s += 15;
    } else if (heartRate > 70) {
      s += 8;
    } else {
      s += 3;
    }

    return s.clamp(0, 100).round();
  }

  /// Merge all signals into a unified stress analysis.
  static StressAnalysis analyze({
    int? questionnaireScore, // null if not taken yet
    double screenTimeHours = 0,
    double socialMediaHours = 0,
    int unlocks = 0,
    bool lateNightUsage = false,
    int steps = 0,
    double sleepHours = 7,
    int exerciseMinutes = 0,
    int heartRate = 72,
  }) {
    final uScore = computeUsageScore(
      screenTimeHours: screenTimeHours,
      socialMediaHours: socialMediaHours,
      unlocks: unlocks,
      lateNightUsage: lateNightUsage,
    );

    final fScore = computeFitnessScore(
      steps: steps,
      sleepHours: sleepHours,
      exerciseMinutes: exerciseMinutes,
      heartRate: heartRate,
    );

    int overall;
    final factors = <String>[];

    if (questionnaireScore != null) {
      overall = (questionnaireScore * wQuestionnaire +
              uScore * wUsage +
              fScore * wFitness)
          .round();
    } else {
      // Without questionnaire, split 50/50
      overall = (uScore * 0.50 + fScore * 0.50).round();
    }
    overall = overall.clamp(0, 100);

    // Determine contributing factors
    if (screenTimeHours > 6) factors.add('High screen time');
    if (socialMediaHours > 2) factors.add('Excessive social media');
    if (lateNightUsage) factors.add('Late-night phone usage');
    if (unlocks > 60) factors.add('Frequent phone checking');
    if (sleepHours < 6) factors.add('Insufficient sleep');
    if (exerciseMinutes < 15) factors.add('Low physical activity');
    if (heartRate > 90) factors.add('Elevated heart rate');

    String primary = 'Balanced lifestyle';
    if (factors.isNotEmpty) {
      primary = factors.first;
    }

    return StressAnalysis(
      overallScore: overall,
      riskLevel: StressAnalysis.computeRiskLevel(overall),
      questionnaireScore: questionnaireScore ?? -1,
      usageScore: uScore,
      fitnessScore: fScore,
      primaryFactor: primary,
      factors: factors,
    );
  }
}

/// Notifier that holds the latest combined stress analysis.
class CombinedStressNotifier extends Notifier<StressAnalysis?> {
  @override
  StressAnalysis? build() => null;

  void update(StressAnalysis analysis) => state = analysis;
  void clear() => state = null;
}

final combinedStressProvider =
    NotifierProvider<CombinedStressNotifier, StressAnalysis?>(
        CombinedStressNotifier.new);
