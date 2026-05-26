/// Application-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'RAYS';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Smart Stress Intelligence - Passive Mental Health Monitoring';

  // Stress Score Thresholds
  static const int stressLow = 0;
  static const int stressMedium = 40;
  static const int stressHigh = 70;
  static const int stressMax = 100;

  // Background monitoring intervals (in minutes)
  static const int normalMonitoringInterval = 240; // 4 hours
  static const int highRiskMonitoringInterval = 60; // 1 hour
  static const int criticalMonitoringInterval = 30; // 30 minutes

  // Sleep parameters
  static const int targetSleepMinutes = 420; // 7 hours
  static const int lateNightStartHour = 0; // midnight
  static const int lateNightEndHour = 4;   // 4 AM

  // Social media session thresholds (in minutes)
  static const int doomScrollThreshold = 20;
  static const int highPickupCountThreshold = 100;
  static const int moderatePickupCountThreshold = 50;

  // Database
  static const String isarDatabaseName = 'rakshak_db';

  // Notification channels
  static const String notifChannelId = 'rakshak_monitoring';
  static const String notifChannelName = 'Rakshak Monitoring';
  static const String notifChannelDesc =
      'Notifications for stress monitoring alerts';
}
