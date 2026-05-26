class UsageStatsModel {
  final int socialMinutes;
  final int pickupCount;
  final bool lateNightUsage;
  final bool doomScrollFlag;
  final int totalScreenMinutes;
  final DateTime collectedAt;

  UsageStatsModel({
    required this.socialMinutes,
    required this.pickupCount,
    required this.lateNightUsage,
    required this.doomScrollFlag,
    required this.totalScreenMinutes,
    required this.collectedAt,
  });

  factory UsageStatsModel.fromJson(Map<String, dynamic> json) {
    return UsageStatsModel(
      socialMinutes: json['socialMinutes'] as int,
      pickupCount: json['pickupCount'] as int,
      lateNightUsage: json['lateNightUsage'] as bool,
      doomScrollFlag: json['doomScrollFlag'] as bool,
      totalScreenMinutes: json['totalScreenMinutes'] as int,
      collectedAt: DateTime.parse(json['collectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'socialMinutes': socialMinutes,
        'pickupCount': pickupCount,
        'lateNightUsage': lateNightUsage,
        'doomScrollFlag': doomScrollFlag,
        'totalScreenMinutes': totalScreenMinutes,
        'collectedAt': collectedAt.toIso8601String(),
      };

  factory UsageStatsModel.fromNativeMap(Map<String, dynamic> map) {
    return UsageStatsModel(
      socialMinutes: map['social_minutes'] as int? ?? 0,
      pickupCount: map['pickup_count'] as int? ?? 0,
      lateNightUsage: map['late_night_usage'] as bool? ?? false,
      doomScrollFlag: map['doom_scroll_flag'] as bool? ?? false,
      totalScreenMinutes: map['total_screen_minutes'] as int? ?? 0,
      collectedAt: DateTime.now(),
    );
  }
}
