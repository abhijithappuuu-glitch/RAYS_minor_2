import 'package:rakshak_ai/core/constants/api_constants.dart';
import 'package:rakshak_ai/core/network/network_service.dart';

/// Remote API service for ML prediction, stress data sync and insights
class StressApiService {
  final NetworkService _networkService;

  StressApiService(this._networkService);

  // ── ML Prediction ─────────────────────────────────────────────────────────

  /// Send behavioural features to the backend RandomForest model.
  ///
  /// Returns a map with:
  ///   stress_score  : int   (0-100)
  ///   risk_level    : String ("low" | "medium" | "high")
  ///   confidence    : double (0-1)
  ///   model_version : String
  ///   timestamp     : String
  ///
  /// Feature keys (backend-expected names):
  ///   social_minutes, late_night_usage (bool), sleep_minutes,
  ///   doom_scroll_flag (bool), pickup_count,
  ///   exercise_minutes (optional), resting_heart_rate (optional)
  Future<Map<String, dynamic>> predictStress(
      Map<String, dynamic> features) async {
    return await _networkService.post(
      ApiConstants.predict,
      data: features,
    );
  }

  /// Quick health-check on the backend.
  Future<Map<String, dynamic>> healthCheck() async {
    return await _networkService.get(ApiConstants.health);
  }

  // ── Existing endpoints ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncStressData(
      Map<String, dynamic> data) async {
    return await _networkService.post(
      ApiConstants.syncStressData,
      data: data,
    );
  }

  Future<Map<String, dynamic>> fetchInsights() async {
    return await _networkService.get(ApiConstants.fetchInsights);
  }

  Future<Map<String, dynamic>> fetchInterventions(
      {required int stressScore}) async {
    return await _networkService.get(
      ApiConstants.interventions,
      queryParameters: {'stress_score': stressScore},
    );
  }

  Future<void> submitAnonymousReport(Map<String, dynamic> report) async {
    await _networkService.post(
      ApiConstants.anonymousReport,
      data: report,
    );
  }

  Future<Map<String, dynamic>> submitFeedback({
    required String deviceId,
    required int reportedStressLevel,
    String context = '',
  }) async {
    return await _networkService.post(
      '/feedback',
      data: {
        'device_id': deviceId,
        'reported_stress_level': reportedStressLevel,
        'context': context,
      },
    );
  }
}
