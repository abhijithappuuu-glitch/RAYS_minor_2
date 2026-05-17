import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_ai/domain/entities/stress_score.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';
import 'package:rakshak_ai/data/models/stress_data_model.dart';
import 'package:rakshak_ai/data/models/usage_stats_model.dart';
import 'package:rakshak_ai/data/models/health_data_model.dart';

void main() {
  group('StressScore Entity', () {
    test('creates correctly with all fields', () {
      final score = StressScore(
        score: 75,
        riskLevel: 'high',
        confidence: 0.85,
        breakdown: {'social': 20, 'sleep': 30},
        timestamp: DateTime(2026, 2, 20),
      );

      expect(score.score, 75);
      expect(score.riskLevel, 'high');
      expect(score.confidence, 0.85);
      expect(score.isHighRisk, true);
      expect(score.isMediumRisk, false);
      expect(score.isLowRisk, false);
    });

    test('isHighRisk returns true for high risk level', () {
      final score = StressScore(
        score: 70,
        riskLevel: 'high',
        confidence: 0.9,
        breakdown: {},
        timestamp: DateTime.now(),
      );
      expect(score.isHighRisk, true);
    });

    test('isMediumRisk returns true for medium risk level', () {
      final score = StressScore(
        score: 55,
        riskLevel: 'medium',
        confidence: 0.8,
        breakdown: {},
        timestamp: DateTime.now(),
      );
      expect(score.isMediumRisk, true);
      expect(score.isHighRisk, false);
      expect(score.isLowRisk, false);
    });

    test('isLowRisk returns true for low risk level', () {
      final score = StressScore(
        score: 25,
        riskLevel: 'low',
        confidence: 0.75,
        breakdown: {},
        timestamp: DateTime.now(),
      );
      expect(score.isLowRisk, true);
    });

    test('toString includes all fields', () {
      final score = StressScore(
        score: 42,
        riskLevel: 'medium',
        confidence: 0.756,
        breakdown: {},
        timestamp: DateTime.now(),
      );
      expect(score.toString(), contains('42'));
      expect(score.toString(), contains('medium'));
    });
  });

  group('UserBehavior Entity', () {
    test('empty factory creates zero-value behavior', () {
      final behavior = UserBehavior.empty();

      expect(behavior.socialMinutes, 0);
      expect(behavior.pickupCount, 0);
      expect(behavior.lateNightUsage, false);
      expect(behavior.doomScrollFlag, false);
      expect(behavior.totalScreenMinutes, 0);
    });

    test('all fields are accessible', () {
      final behavior = UserBehavior(
        socialMinutes: 120,
        pickupCount: 80,
        lateNightUsage: true,
        doomScrollFlag: true,
        totalScreenMinutes: 300,
        timestamp: DateTime.now(),
      );

      expect(behavior.socialMinutes, 120);
      expect(behavior.pickupCount, 80);
      expect(behavior.lateNightUsage, true);
      expect(behavior.doomScrollFlag, true);
      expect(behavior.totalScreenMinutes, 300);
    });

    test('hasHighSocialUsage is true when > 120 minutes', () {
      final behavior = UserBehavior(
        socialMinutes: 150,
        pickupCount: 50,
        lateNightUsage: false,
        doomScrollFlag: false,
        totalScreenMinutes: 200,
        timestamp: DateTime.now(),
      );
      expect(behavior.hasHighSocialUsage, true);
    });

    test('hasExcessivePickups is true when > 100', () {
      final behavior = UserBehavior(
        socialMinutes: 60,
        pickupCount: 120,
        lateNightUsage: false,
        doomScrollFlag: false,
        totalScreenMinutes: 200,
        timestamp: DateTime.now(),
      );
      expect(behavior.hasExcessivePickups, true);
    });
  });

  group('StressDataModel', () {
    test('creates with all required fields', () {
      final model = StressDataModel(
        id: 'test-001',
        stressScore: 65,
        riskLevel: 'medium',
        confidence: 0.88,
        breakdown: {'social': 15, 'sleep': 25},
        timestamp: DateTime(2026, 2, 20, 14, 30),
      );

      expect(model.id, 'test-001');
      expect(model.stressScore, 65);
      expect(model.riskLevel, 'medium');
      expect(model.synced, false);
    });

    test('copyWith creates a modified copy', () {
      final model = StressDataModel(
        id: 'test-001',
        stressScore: 65,
        riskLevel: 'medium',
        confidence: 0.88,
        breakdown: {},
        timestamp: DateTime(2026, 2, 20),
      );

      final synced = model.copyWith(synced: true);
      expect(synced.synced, true);
      expect(synced.stressScore, 65); // unchanged
    });
  });

  group('UsageStatsModel', () {
    test('creates from native platform map', () {
      final nativeMap = {
        'social_minutes': 90,
        'pickup_count': 45,
        'late_night_usage': true,
        'doom_scroll_flag': false,
        'total_screen_minutes': 240,
      };

      final model = UsageStatsModel.fromNativeMap(nativeMap);
      expect(model.socialMinutes, 90);
      expect(model.pickupCount, 45);
      expect(model.lateNightUsage, true);
      expect(model.doomScrollFlag, false);
      expect(model.totalScreenMinutes, 240);
    });

    test('handles missing native map fields gracefully', () {
      final model = UsageStatsModel.fromNativeMap({});
      expect(model.socialMinutes, 0);
      expect(model.pickupCount, 0);
      expect(model.lateNightUsage, false);
      expect(model.doomScrollFlag, false);
      expect(model.totalScreenMinutes, 0);
    });
  });

  group('HealthDataModel', () {
    test('handles null optional fields', () {
      final model = HealthDataModel(
        sleepMinutes: 360,
        exerciseMinutes: 0,
        restingHeartRate: null,
        steps: null,
        collectedAt: DateTime.now(),
      );

      expect(model.restingHeartRate, isNull);
      expect(model.steps, isNull);
      expect(model.sleepMinutes, 360);
    });
  });
}
