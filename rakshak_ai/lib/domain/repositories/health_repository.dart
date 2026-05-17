import 'package:rakshak_ai/data/models/health_data_model.dart';

/// Abstract repository for health data access (Health Connect / HealthKit)
abstract class HealthRepository {
  /// Fetch latest health data from device health platform
  Future<HealthDataModel> getHealthData();

  /// Check if health permissions have been granted
  Future<bool> hasHealthPermissions();

  /// Request health data permissions from the user
  Future<bool> requestHealthPermissions();
}
