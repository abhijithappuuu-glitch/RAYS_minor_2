import 'package:rakshak_ai/features/smart_notifications/intervention_engine.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final InterventionEngine _engine = InterventionEngine();

  Future<void> initialize() async {
    await initializeTimezone();
    await _engine.initialize();
    
    // Schedule daily summary at 8 PM
    await _engine.scheduleDailySummary(hour: 20, minute: 0);
  }

  Future<void> processStressUpdate(
    StressScore current,
    StressScore? previous,
    Map<String, dynamic> behaviorData,
  ) async {
    await _engine.analyzeAndIntervene(
      currentScore: current,
      previousScore: previous,
      behaviorData: behaviorData,
    );
  }

  Future<void> disableNotifications() async {
    await _engine.cancelAll();
  }
}
