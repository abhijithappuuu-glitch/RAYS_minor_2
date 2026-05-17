/// Domain entity representing a calculated stress score
class StressScore {
  final int score;
  final String riskLevel;
  final double confidence;
  final Map<String, dynamic> breakdown;
  final DateTime timestamp;

  StressScore({
    required this.score,
    required this.riskLevel,
    required this.confidence,
    required this.breakdown,
    required this.timestamp,
  });

  bool get isHighRisk => riskLevel == 'high';
  bool get isMediumRisk => riskLevel == 'medium';
  bool get isLowRisk => riskLevel == 'low';

  @override
  String toString() =>
      'StressScore(score: $score, risk: $riskLevel, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}
