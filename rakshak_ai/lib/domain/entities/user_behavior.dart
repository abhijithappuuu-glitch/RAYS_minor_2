/// Domain entity representing a user's behavioral data snapshot
class UserBehavior {
  final int socialMinutes;
  final int pickupCount;
  final bool lateNightUsage;
  final bool doomScrollFlag;
  final int totalScreenMinutes;
  final DateTime timestamp;

  UserBehavior({
    required this.socialMinutes,
    required this.pickupCount,
    required this.lateNightUsage,
    required this.doomScrollFlag,
    required this.totalScreenMinutes,
    required this.timestamp,
  });

  /// Empty/default behavior when data is unavailable
  factory UserBehavior.empty() {
    return UserBehavior(
      socialMinutes: 0,
      pickupCount: 0,
      lateNightUsage: false,
      doomScrollFlag: false,
      totalScreenMinutes: 0,
      timestamp: DateTime.now(),
    );
  }

  bool get hasHighSocialUsage => socialMinutes > 120; // > 2 hours
  bool get hasExcessivePickups => pickupCount > 100;
}
