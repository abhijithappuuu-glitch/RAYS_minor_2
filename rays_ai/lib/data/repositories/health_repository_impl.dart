import 'package:health/health.dart';
import 'package:rakshak_ai/data/models/health_data_model.dart';
import 'package:rakshak_ai/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final Health _health = Health();

  static const List<HealthDataType> _requiredTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
  ];

  @override
  Future<HealthDataModel> getHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final yesterday = midnight.subtract(const Duration(days: 1));

    try {
      final hasPerms = await hasHealthPermissions();
      if (!hasPerms) {
        return _emptyHealthData();
      }

      // Fetch all health data for the last 24 hours
      final healthData = await _health.getHealthDataFromTypes(
        types: _requiredTypes,
        startTime: yesterday,
        endTime: now,
      );

      // Remove duplicates
      final cleanData = _health.removeDuplicates(healthData);

      // Extract sleep duration
      int sleepMinutes = 0;
      for (final dp in cleanData) {
        if (dp.type == HealthDataType.SLEEP_ASLEEP ||
            dp.type == HealthDataType.SLEEP_IN_BED) {
          sleepMinutes += dp.dateTo.difference(dp.dateFrom).inMinutes;
        }
      }

      // Extract resting heart rate (average of values)
      final heartRatePoints = cleanData
          .where((dp) => dp.type == HealthDataType.HEART_RATE)
          .toList();
      int? avgHeartRate;
      if (heartRatePoints.isNotEmpty) {
        final sum = heartRatePoints.fold<double>(
          0,
          (prev, dp) => prev + (dp.value as NumericHealthValue).numericValue,
        );
        avgHeartRate = (sum / heartRatePoints.length).round();
      }

      // Extract steps
      int totalSteps = 0;
      for (final dp in cleanData) {
        if (dp.type == HealthDataType.STEPS) {
          totalSteps += (dp.value as NumericHealthValue).numericValue.toInt();
        }
      }

      // Estimate exercise minutes from steps (10k steps ≈ 60 min)
      int exerciseMinutes = 0;
      if (totalSteps > 3000) {
        exerciseMinutes = (totalSteps / 166).round().clamp(0, 180);
      }

      return HealthDataModel(
        sleepMinutes: sleepMinutes > 0 ? sleepMinutes : null,
        exerciseMinutes: exerciseMinutes > 0 ? exerciseMinutes : null,
        restingHeartRate: avgHeartRate,
        steps: totalSteps > 0 ? totalSteps : null,
        collectedAt: now,
      );
    } catch (e) {
      // Graceful degradation: return empty data on failure
      return _emptyHealthData();
    }
  }

  @override
  Future<bool> hasHealthPermissions() async {
    try {
      final result = await _health.hasPermissions(
        _requiredTypes,
        permissions: _requiredTypes
            .map((_) => HealthDataAccess.READ)
            .toList(),
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestHealthPermissions() async {
    try {
      return await _health.requestAuthorization(
        _requiredTypes,
        permissions: _requiredTypes
            .map((_) => HealthDataAccess.READ)
            .toList(),
      );
    } catch (e) {
      return false;
    }
  }

  HealthDataModel _emptyHealthData() {
    return HealthDataModel(
      restingHeartRate: null,
      sleepMinutes: null,
      exerciseMinutes: null,
      steps: null,
      collectedAt: DateTime.now(),
    );
  }
}
