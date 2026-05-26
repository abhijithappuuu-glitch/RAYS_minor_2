import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/features/context_intelligence/context_collector.dart';

/// Context intelligence state
final contextSnapshotProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final collector = getIt<ContextIntelligenceCollector>();
  return await collector.getContextSnapshot();
});

/// Night risk score
final nightRiskScoreProvider = FutureProvider<int>((ref) async {
  final context = await ref.watch(contextSnapshotProvider.future);

  final isNightTime = context['is_night_time'] as bool? ?? false;
  final isDarkRoom = context['is_dark_room'] as bool? ?? false;
  final isCharging = context['is_charging'] as bool? ?? false;

  // Calculate night risk score
  if (!isNightTime) return 0;

  int risk = 0;
  if (isDarkRoom) risk += 40;
  if (isCharging) risk += 30;
  if (isDarkRoom && isCharging) risk = 100;

  return risk;
});

/// Ambient light level
final ambientLuxProvider = FutureProvider<double>((ref) async {
  final context = await ref.watch(contextSnapshotProvider.future);
  return (context['ambient_lux'] as num?)?.toDouble() ?? -1;
});

/// Charging state
final isChargingProvider = FutureProvider<bool>((ref) async {
  final context = await ref.watch(contextSnapshotProvider.future);
  return context['is_charging'] as bool? ?? false;
});

