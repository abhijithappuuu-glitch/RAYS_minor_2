import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/data/models/health_data_model.dart';
import 'package:rakshak_ai/domain/repositories/health_repository.dart';

/// Health data state
final healthDataProvider = FutureProvider<HealthDataModel>((ref) async {
  final repository = getIt<HealthRepository>();

  final hasPermissions = await repository.hasHealthPermissions();
  if (!hasPermissions) {
    await repository.requestHealthPermissions();
  }

  return await repository.getHealthData();
});

/// Health permissions state
final healthPermissionsProvider = FutureProvider<bool>((ref) async {
  final repository = getIt<HealthRepository>();
  return await repository.hasHealthPermissions();
});

/// Sleep hours computed from health data
final sleepHoursProvider = FutureProvider<double>((ref) async {
  final healthData = await ref.watch(healthDataProvider.future);
  return (healthData.sleepMinutes ?? 0) / 60.0;
});

/// Exercise minutes from health data
final exerciseMinutesProvider = FutureProvider<int>((ref) async {
  final healthData = await ref.watch(healthDataProvider.future);
  return healthData.exerciseMinutes ?? 0;
});

/// Weekly sleep consistency tracking
class SleepConsistencyNotifier extends Notifier<List<double>> {
  @override
  List<double> build() => [];

  void updateSleepData(List<double> weeklyHours) {
    state = weeklyHours;
  }

  double get averageSleep {
    if (state.isEmpty) return 0;
    return state.reduce((a, b) => a + b) / state.length;
  }

  double get consistency {
    if (state.length < 2) return 1.0;
    final avg = averageSleep;
    final variance = state.map((h) => (h - avg) * (h - avg)).reduce((a, b) => a + b) / state.length;
    final stdDev = variance > 0 ? sqrt(variance) : 0.0;
    // Lower std dev = higher consistency (normalized to 0-1)
    return (1 - (stdDev / 4)).clamp(0.0, 1.0);
  }
}

final sleepConsistencyProvider =
    NotifierProvider<SleepConsistencyNotifier, List<double>>(
  SleepConsistencyNotifier.new,
);

