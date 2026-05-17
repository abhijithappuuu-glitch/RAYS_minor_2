import 'package:rakshak_ai/domain/entities/user_behavior.dart';

/// Abstract repository for device usage statistics
abstract class UsageRepository {
  Future<UserBehavior> getUsageStats();
  Future<bool> hasUsagePermission();
  Future<void> requestUsagePermission();
}
