/// ML Model constants and thresholds
class MLConstants {
  MLConstants._();

  // Stress score weights
  static const double socialMediaWeight = 0.3;
  static const double socialMediaMaxContribution = 30.0;
  static const double lateNightPenalty = 20.0;
  static const double sleepDeficitWeight = 0.5;
  static const double doomScrollPenalty = 15.0;
  static const double highPickupPenalty = 10.0;
  static const double moderatePickupPenalty = 5.0;
  static const double exerciseBenefitWeight = 0.2;
  static const double exerciseMaxBenefit = 15.0;
  static const double highHeartRatePenalty = 10.0;
  static const double lowHeartRateBenefit = 5.0;

  // Confidence levels
  static const double baseConfidence = 0.7;
  static const double exerciseConfidenceBonus = 0.1;
  static const double heartRateConfidenceBonus = 0.1;
  static const double sleepConfidenceBonus = 0.1;

  // Heart rate thresholds
  static const int highRestingHeartRate = 80;
  static const int lowRestingHeartRate = 60;

  // Night risk weights
  static const int darkRoomScreenRisk = 40;
  static const int chargingScreenRisk = 30;
  static const int allIndicatorsRisk = 100;

  // Risk level thresholds
  static const int highRiskThreshold = 70;
  static const int mediumRiskThreshold = 40;
}
