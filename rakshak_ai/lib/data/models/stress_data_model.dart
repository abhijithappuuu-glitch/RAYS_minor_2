class StressDataModel {
  final String id;
  final int stressScore;
  final String riskLevel;
  final double confidence;
  final Map<String, dynamic> breakdown;
  final DateTime timestamp;
  final bool synced;

  StressDataModel({
    required this.id,
    required this.stressScore,
    required this.riskLevel,
    required this.confidence,
    required this.breakdown,
    required this.timestamp,
    this.synced = false,
  });

  factory StressDataModel.fromJson(Map<String, dynamic> json) {
    return StressDataModel(
      id: json['id'] as String,
      stressScore: json['stressScore'] as int,
      riskLevel: json['riskLevel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      breakdown: json['breakdown'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stressScore': stressScore,
        'riskLevel': riskLevel,
        'confidence': confidence,
        'breakdown': breakdown,
        'timestamp': timestamp.toIso8601String(),
        'synced': synced,
      };

  StressDataModel copyWith({
    String? id,
    int? stressScore,
    String? riskLevel,
    double? confidence,
    Map<String, dynamic>? breakdown,
    DateTime? timestamp,
    bool? synced,
  }) {
    return StressDataModel(
      id: id ?? this.id,
      stressScore: stressScore ?? this.stressScore,
      riskLevel: riskLevel ?? this.riskLevel,
      confidence: confidence ?? this.confidence,
      breakdown: breakdown ?? this.breakdown,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }
}
