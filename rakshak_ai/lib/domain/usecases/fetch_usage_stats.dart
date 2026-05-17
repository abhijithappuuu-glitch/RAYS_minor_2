import 'package:rakshak_ai/domain/entities/user_behavior.dart';
import 'package:rakshak_ai/domain/repositories/usage_repository.dart';

/// Use case: Fetch device usage statistics via native platform channel
class FetchUsageStats {
  final UsageRepository _repository;

  FetchUsageStats(this._repository);

  Future<UserBehavior> execute() async {
    final hasPermission = await _repository.hasUsagePermission();
    if (!hasPermission) {
      await _repository.requestUsagePermission();
      // Return empty if permission not yet granted
      return UserBehavior.empty();
    }
    return await _repository.getUsageStats();
  }

  Future<bool> checkPermission() async {
    return await _repository.hasUsagePermission();
  }
}
