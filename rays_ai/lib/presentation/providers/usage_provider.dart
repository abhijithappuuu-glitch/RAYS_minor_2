import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/domain/repositories/usage_repository.dart';

/// Usage permission state
final usagePermissionProvider = FutureProvider<bool>((ref) async {
  final repository = getIt<UsageRepository>();
  return await repository.hasUsagePermission();
});

/// Request usage permission
final requestUsagePermissionProvider = FutureProvider<void>((ref) async {
  final repository = getIt<UsageRepository>();
  await repository.requestUsagePermission();
});

