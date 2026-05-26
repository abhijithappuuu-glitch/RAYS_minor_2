import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:convert';

typedef TZDateTime = tz.TZDateTime;
final _local = tz.local;

Future<void> initializeTimezone() async {
  tzdata.initializeTimeZones();
}

class InterventionEngine {
  static final InterventionEngine _instance = InterventionEngine._internal();
  factory InterventionEngine() => _instance;
  InterventionEngine._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Navigate to relevant screen based on action from jsonDecode(payload)
    }
  }

  /// Analyze stress data and trigger appropriate intervention
  Future<void> analyzeAndIntervene({
    required StressScore currentScore,
    StressScore? previousScore,
    required Map<String, dynamic> behaviorData,
  }) async {
    // Check if notifications are disabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (!notificationsEnabled) return;

    // Rule-based intervention logic
    await _checkHighStressIntervention(currentScore, behaviorData);
    await _checkSleepIntervention(currentScore, behaviorData);
    await _checkDoomScrollIntervention(behaviorData);
    await _checkLateNightIntervention(behaviorData);
    await _checkPositiveReinforcement(currentScore, previousScore);
  }

  /// High stress + poor sleep → Breathing exercise
  Future<void> _checkHighStressIntervention(
    StressScore score,
    Map<String, dynamic> data,
  ) async {
    if (score.riskLevel != 'high') return;

    final sleepMinutes = data['sleep_minutes'] as int? ?? 420;
    
    if (sleepMinutes < 360) { // Less than 6 hours
      await _sendNotification(
        id: 1,
        title: '🌟 Take a Mindful Break',
        body: 'Your stress levels are high and sleep is low. Try a 5-minute breathing exercise?',
        payload: jsonEncode({
          'action': 'breathing_exercise',
          'type': 'intervention',
        }),
        importance: Importance.high,
      );

      await _logIntervention('high_stress_low_sleep', score.score);
    }
  }

  /// Late night usage → Gentle nudge
  Future<void> _checkLateNightIntervention(Map<String, dynamic> data) async {
    final lateNightUsage = data['late_night_usage'] as bool? ?? false;
    
    if (!lateNightUsage) return;

    // Check if already notified today
    final lastNotification = await _getLastNotificationTime('late_night');
    if (lastNotification != null) {
      final hoursSince = DateTime.now().difference(lastNotification).inHours;
      if (hoursSince < 20) return; // Don't spam
    }

    await _sendNotification(
      id: 2,
      title: '🌙 Late Night Alert',
      body: 'Using your phone late disrupts sleep. Consider winding down?',
      payload: jsonEncode({
        'action': 'sleep_tips',
        'type': 'gentle_nudge',
      }),
      importance: Importance.defaultImportance,
    );

    await _saveNotificationTime('late_night');
    await _logIntervention('late_night_nudge', 0);
  }

  /// Doom scrolling detection → Break reminder
  Future<void> _checkDoomScrollIntervention(Map<String, dynamic> data) async {
    final doomScroll = data['doom_scroll_flag'] as bool? ?? false;
    
    if (!doomScroll) return;

    await _sendNotification(
      id: 3,
      title: '📱 Screen Break Reminder',
      body: 'You\'ve been scrolling for a while. Time for a quick break?',
      payload: jsonEncode({
        'action': 'take_break',
        'type': 'behavior_alert',
      }),
      importance: Importance.defaultImportance,
    );

    await _logIntervention('doom_scroll_alert', 0);
  }

  /// Sleep quality intervention
  Future<void> _checkSleepIntervention(
    StressScore score,
    Map<String, dynamic> data,
  ) async {
    final sleepMinutes = data['sleep_minutes'] as int? ?? 420;
    
    if (sleepMinutes < 300) { // Less than 5 hours
      await _sendNotification(
        id: 4,
        title: '😴 Sleep Is Critical',
        body: 'You only slept ${(sleepMinutes / 60).toStringAsFixed(1)} hours. Prioritize rest tonight.',
        payload: jsonEncode({
          'action': 'sleep_schedule',
          'type': 'health_alert',
        }),
        importance: Importance.high,
      );

      await _logIntervention('poor_sleep_alert', sleepMinutes);
    }
  }

  /// Positive reinforcement for improving trends
  Future<void> _checkPositiveReinforcement(
    StressScore? current,
    StressScore? previous,
  ) async {
    if (current == null || previous == null) return;

    final improvement = previous.score - current.score;
    
    if (improvement >= 15) { // Significant improvement
      await _sendNotification(
        id: 5,
        title: '🎉 Great Progress!',
        body: 'Your stress decreased by $improvement points. Keep up the healthy habits!',
        payload: jsonEncode({
          'action': 'view_progress',
          'type': 'positive_feedback',
        }),
        importance: Importance.defaultImportance,
      );

      await _logIntervention('positive_reinforcement', improvement);
    }
  }

  /// Send notification with proper Android/iOS configuration
  Future<void> _sendNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.defaultImportance,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'interventions',
      'Smart Interventions',
      channelDescription: 'Context-aware stress management notifications',
      importance: importance,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFFFFD700),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'RAYS',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Schedule daily stress summary
  Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Daily Summary',
      channelDescription: 'Your daily stress and wellness summary',
      importance: Importance.defaultImportance,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      id: 100,
      title: '📊 Daily Wellness Summary',
      body: 'Tap to view your stress trends and insights',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Helper: Get next scheduled time
  TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = TZDateTime.now(_local);
    var scheduledDate = TZDateTime(
      _local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Logging helpers
  Future<void> _logIntervention(String type, int value) async {
    final prefs = await SharedPreferences.getInstance();
    final interventions = prefs.getStringList('intervention_log') ?? [];
    
    interventions.add(jsonEncode({
      'type': type,
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    }));

    // Keep only last 100 interventions
    if (interventions.length > 100) {
      interventions.removeAt(0);
    }

    await prefs.setStringList('intervention_log', interventions);
  }

  Future<DateTime?> _getLastNotificationTime(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_notification_$type');
    
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _saveNotificationTime(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_notification_$type',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
