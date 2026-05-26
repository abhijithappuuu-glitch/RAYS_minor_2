import 'package:flutter/services.dart';
import 'package:rakshak_ai/data/models/usage_stats_model.dart';
import 'package:rakshak_ai/domain/repositories/usage_repository.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';

class UsageRepositoryImpl implements UsageRepository {
  static const _channel = MethodChannel('rakshak.ai/usage_stats');

  @override
  Future<UserBehavior> getUsageStats() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getUsageStats');

      if (result != null) {
        final map = result.cast<String, dynamic>();
        final model = UsageStatsModel.fromNativeMap(map);
        return UserBehavior(
          socialMinutes: model.socialMinutes,
          pickupCount: model.pickupCount,
          lateNightUsage: model.lateNightUsage,
          doomScrollFlag: model.doomScrollFlag,
          totalScreenMinutes: model.totalScreenMinutes,
          timestamp: model.collectedAt,
        );
      }
    } on PlatformException catch (_) {
      // Handle platform errors gracefully
    }

    // Return empty defaults if native call fails
    return UserBehavior.empty();
  }

  @override
  Future<bool> hasUsagePermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (_) {
      // Silently handle
    }
  }
}
