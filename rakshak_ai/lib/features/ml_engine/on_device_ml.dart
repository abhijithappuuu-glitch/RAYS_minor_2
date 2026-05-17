import 'dart:math';

class OnDeviceMLEngine {
  /// Lightweight stress heuristic scoring
  /// Returns stress score 0-100 with confidence level
  static Map<String, dynamic> calculateStressScore({
    required int socialMinutes,
    required bool lateNightUsage,
    required int sleepMinutes,
    required bool doomScrollFlag,
    required int pickupCount,
    int? exerciseMinutes,
    int? restingHeartRate,
  }) {
    double stressBase = 0.0;
    
    // Social media impact (0-30 points)
    stressBase += min(socialMinutes * 0.3, 30.0);
    
    // Late night penalty (0-20 points)
    if (lateNightUsage) {
      stressBase += 20.0;
    }
    
    // Sleep deficit calculation — capped at 30 pts so missing data (0 min)
    // doesn't inflate the score to 210 pts when Health Connect is denied.
    const targetSleep = 7 * 60; // 7 hours
    final sleepDeficit = max(0, targetSleep - sleepMinutes);
    stressBase += min(sleepDeficit * 0.5, 30.0);
    
    // Doom scrolling flag (0-15 points)
    if (doomScrollFlag) {
      stressBase += 15.0;
    }
    
    // Pickup frequency stress
    if (pickupCount > 100) {
      stressBase += 10.0;
    } else if (pickupCount > 50) {
      stressBase += 5.0;
    }
    
    // Exercise benefit (negative stress)
    if (exerciseMinutes != null && exerciseMinutes > 0) {
      stressBase -= min(exerciseMinutes * 0.2, 15.0);
    }
    
    // Heart rate indicator (if available)
    if (restingHeartRate != null) {
      if (restingHeartRate > 80) {
        stressBase += 10.0;
      } else if (restingHeartRate < 60) {
        stressBase -= 5.0; // Athlete benefit
      }
    }
    
    // Normalize to 0-100
    final stressScore = min(100.0, max(0.0, stressBase)).round();
    
    // Calculate confidence based on data availability
    double confidence = 0.7; // Base confidence
    if (exerciseMinutes != null) confidence += 0.1;
    if (restingHeartRate != null) confidence += 0.1;
    if (sleepMinutes > 0) confidence += 0.1;
    
    final riskLevel = _getRiskLevel(stressScore);
    
    return {
      'stress_score': stressScore,
      'risk_level': riskLevel,
      'confidence': confidence,
      'breakdown': {
        'social_impact': min(socialMinutes * 0.3, 30.0).round(),
        'sleep_impact': (sleepDeficit * 0.5).round(),
        'late_night_penalty': lateNightUsage ? 20 : 0,
        'doom_scroll_penalty': doomScrollFlag ? 15 : 0,
      }
    };
  }
  
  static String _getRiskLevel(int score) {
    if (score >= 70) return 'high';
    if (score >= 40) return 'medium';
    return 'low';
  }
  
  /// Calculate night risk score
  static int calculateNightRiskScore({
    required bool isNightTime,
    required bool isDarkRoom,
    required bool isCharging,
    required bool screenOn,
  }) {
    if (!isNightTime) return 0;
    
    int risk = 0;
    
    if (screenOn && isDarkRoom) {
      risk += 40; // Screen in dark damages circadian rhythm
    }
    
    if (isCharging && screenOn) {
      risk += 30; // Bedtime phone usage pattern
    }
    
    if (isDarkRoom && isCharging && screenOn) {
      risk = 100; // Maximum risk: all indicators present
    }
    
    return risk;
  }
}
