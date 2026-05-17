class HealthDataModel {
  final int? restingHeartRate;
  final int? sleepMinutes;
  final int? exerciseMinutes;
  final int? steps;
  final DateTime collectedAt;

  HealthDataModel({
    this.restingHeartRate,
    this.sleepMinutes,
    this.exerciseMinutes,
    this.steps,
    required this.collectedAt,
  });

  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    return HealthDataModel(
      restingHeartRate: json['restingHeartRate'] as int?,
      sleepMinutes: json['sleepMinutes'] as int?,
      exerciseMinutes: json['exerciseMinutes'] as int?,
      steps: json['steps'] as int?,
      collectedAt: DateTime.parse(json['collectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'restingHeartRate': restingHeartRate,
        'sleepMinutes': sleepMinutes,
        'exerciseMinutes': exerciseMinutes,
        'steps': steps,
        'collectedAt': collectedAt.toIso8601String(),
      };
}
