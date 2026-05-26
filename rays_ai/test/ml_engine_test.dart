import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_ai/features/ml_engine/on_device_ml.dart';

void main() {
  group('OnDeviceMLEngine — Stress Score Calculator', () {
    test('returns low risk for healthy behavior', () {
      final result = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 20,
        lateNightUsage: false,
        sleepMinutes: 480, // 8 hours
        doomScrollFlag: false,
        pickupCount: 30,
        exerciseMinutes: 45,
      );

      expect(result['stress_score'], isA<int>());
      expect(result['risk_level'], 'low');
      expect(result['confidence'], isA<double>());
      expect(result['stress_score'] as int, lessThan(40));
    });

    test('returns high risk for unhealthy behavior', () {
      final result = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 200,
        lateNightUsage: true,
        sleepMinutes: 180, // 3 hours
        doomScrollFlag: true,
        pickupCount: 120,
        exerciseMinutes: 0,
      );

      expect(result['stress_score'] as int, greaterThanOrEqualTo(70));
      expect(result['risk_level'], 'high');
    });

    test('returns medium risk for mixed behavior', () {
      final result = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 390, // 6.5 hours
        doomScrollFlag: true,
        pickupCount: 40,
        exerciseMinutes: 20,
      );

      expect(result['stress_score'] as int, greaterThanOrEqualTo(30));
      expect(result['stress_score'] as int, lessThanOrEqualTo(80));
      expect(result['risk_level'], anyOf('medium', 'high'));
    });

    test('score is clamped between 0 and 100', () {
      // Worst case scenario
      final worst = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 999,
        lateNightUsage: true,
        sleepMinutes: 0,
        doomScrollFlag: true,
        pickupCount: 999,
        exerciseMinutes: 0,
      );
      expect(worst['stress_score'] as int, lessThanOrEqualTo(100));

      // Best case scenario
      final best = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 0,
        lateNightUsage: false,
        sleepMinutes: 600,
        doomScrollFlag: false,
        pickupCount: 5,
        exerciseMinutes: 120,
      );
      expect(best['stress_score'] as int, greaterThanOrEqualTo(0));
    });

    test('confidence is between 0 and 1', () {
      final result = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      final confidence = result['confidence'] as double;
      expect(confidence, greaterThanOrEqualTo(0.0));
      expect(confidence, lessThanOrEqualTo(1.0));
    });

    test('late night usage increases score', () {
      final withoutLateNight = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      final withLateNight = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: true,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      expect(
        withLateNight['stress_score'] as int,
        greaterThan(withoutLateNight['stress_score'] as int),
      );
    });

    test('doom scrolling increases score', () {
      final withoutDoom = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      final withDoom = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: true,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      expect(
        withDoom['stress_score'] as int,
        greaterThan(withoutDoom['stress_score'] as int),
      );
    });

    test('exercise reduces score', () {
      final noExercise = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 80,
        lateNightUsage: false,
        sleepMinutes: 360,
        doomScrollFlag: false,
        pickupCount: 50,
        exerciseMinutes: 0,
      );

      final withExercise = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 80,
        lateNightUsage: false,
        sleepMinutes: 360,
        doomScrollFlag: false,
        pickupCount: 50,
        exerciseMinutes: 60,
      );

      expect(
        withExercise['stress_score'] as int,
        lessThan(noExercise['stress_score'] as int),
      );
    });

    test('more sleep reduces score', () {
      final poorSleep = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 240, // 4 hours
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      final goodSleep = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 480, // 8 hours
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
      );

      expect(
        goodSleep['stress_score'] as int,
        lessThan(poorSleep['stress_score'] as int),
      );
    });

    test('optional heart rate parameter affects score', () {
      final normal = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
        restingHeartRate: 65,
      );

      final elevated = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 60,
        lateNightUsage: false,
        sleepMinutes: 420,
        doomScrollFlag: false,
        pickupCount: 40,
        exerciseMinutes: 30,
        restingHeartRate: 110,
      );

      expect(
        elevated['stress_score'] as int,
        greaterThan(normal['stress_score'] as int),
      );
    });
  });

  group('OnDeviceMLEngine — Night Risk Calculator', () {
    test('detects night risk scenario', () {
      final result = OnDeviceMLEngine.calculateNightRiskScore(
        isNightTime: true,
        isDarkRoom: true,
        isCharging: true,
        screenOn: true,
      );

      expect(result, greaterThan(50));
    });

    test('no risk during daytime', () {
      final result = OnDeviceMLEngine.calculateNightRiskScore(
        isNightTime: false,
        isDarkRoom: false,
        isCharging: false,
        screenOn: true,
      );

      expect(result, equals(0));
    });

    test('no risk when screen is off', () {
      final result = OnDeviceMLEngine.calculateNightRiskScore(
        isNightTime: true,
        isDarkRoom: true,
        isCharging: true,
        screenOn: false,
      );

      expect(result, equals(0));
    });
  });

  group('StressScore — Entity', () {
    test('risk level boundaries are correct', () {
      // Score 0-39 should be low
      // Score 40-69 should be medium
      // Score 70-100 should be high
      // This tests the ML engine's mapping
      final low = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 10,
        lateNightUsage: false,
        sleepMinutes: 480,
        doomScrollFlag: false,
        pickupCount: 20,
        exerciseMinutes: 60,
      );
      expect(low['risk_level'], 'low');

      final high = OnDeviceMLEngine.calculateStressScore(
        socialMinutes: 300,
        lateNightUsage: true,
        sleepMinutes: 120,
        doomScrollFlag: true,
        pickupCount: 150,
        exerciseMinutes: 0,
      );
      expect(high['risk_level'], 'high');
    });
  });
}
