import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contributing factor from the backend AI engine
class ContributingFactor {
  final String name;
  final String detail;
  final String severity; // 'high' | 'medium' | 'low'

  const ContributingFactor({
    required this.name,
    required this.detail,
    this.severity = 'medium',
  });

  factory ContributingFactor.fromJson(Map<String, dynamic> j) =>
      ContributingFactor(
        name: j['name'] as String? ?? '',
        detail: j['detail'] as String? ?? '',
        severity: j['severity'] as String? ?? 'medium',
      );
}

/// Result object returned by the backend prediction
class StressAnalysis {
  final int overallScore;       // 0-100
  final String riskLevel;       // Low, Medium, High
  final int questionnaireScore; // -1 if not taken
  final int usageScore;         // backend-computed 0-100
  final int fitnessScore;       // backend-computed 0-100

  final String primaryFactor;
  final List<String> factors;
  final List<ContributingFactor> contributingFactors;
  final List<String> actionableTips;

  final int? mlScore;
  final double? mlConfidence;
  final String? contextualMessage;
  final bool mlEnhanced;

  StressAnalysis({
    required this.overallScore,
    required this.riskLevel,
    this.questionnaireScore = -1,
    this.usageScore = 0,
    this.fitnessScore = 0,
    this.primaryFactor = '',
    this.factors = const [],
    this.contributingFactors = const [],
    this.actionableTips = const [],
    this.mlScore,
    this.mlConfidence,
    this.contextualMessage,
    this.mlEnhanced = false,
  });

  static String computeRiskLevel(int score) {
    if (score <= 35) return 'Low';
    if (score <= 65) return 'Medium';
    return 'High';
  }
}

/// The single source of truth for stress analysis.
///
/// This engine does ONE thing: package data, send it to the Python backend,
/// and return the result. All scoring, ML, and advice generation happens
/// server-side.
class StressAnalysisEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // Replace this with your actual ngrok URL before the demo!
  // Example: 'https://abc123.ngrok-free.app/api/v1/predict'
  // ──────────────────────────────────────────────────────────────────────────
  static const String _backendUrl = 'https://honest-peaches-agree.loca.lt/api/v1/predict';
  static const String _apiKey = 'rakshak-mobile-key-2026';

  /// Build the JSON payload for the backend.
  ///
  /// Real device data always wins. Demo/random fallback only activates when
  /// the value is null OR zero (Health Connect returned nothing).
  /// For boolean flags, null → random demo value.
  static Map<String, dynamic> buildDemoPayload({
    int? screenTimeMinutes,
    int? unlockCount,
    int? socialMediaMinutes,
    int? sleepMinutes,
    int? questionnaireScore,
    int? exerciseMinutes,
    int? restingHeartRate,
    bool? lateNightUsage,
    bool? doomScrollFlag,
    int? pickupCount,
  }) {
    final random = Random();

    return {
      'device_id': 'demo-device-${random.nextInt(999)}',
      'social_minutes': socialMediaMinutes ?? 0,
      'late_night_usage': lateNightUsage ?? false,
      'sleep_minutes': sleepMinutes ?? 0,
      'doom_scroll_flag': doomScrollFlag ?? false,
      'pickup_count': pickupCount ?? 0,
      'total_screen_minutes': screenTimeMinutes ?? 0,
      'exercise_minutes': exerciseMinutes ?? 0,
      'resting_heart_rate': restingHeartRate ?? 0,
      'questionnaire_score': questionnaireScore,
    };
  }

  /// The single entry point — sends data to Python and returns the result.
  ///
  /// If real sensor data is available, pass it in. Otherwise, demo data
  /// is auto-generated.
  static Future<Map<String, dynamic>> analyzeStress({
    int? socialMediaMinutes,
    int? sleepMinutes,
    int? screenTimeMinutes,
    int? unlockCount,
    int? exerciseMinutes,
    int? restingHeartRate,
    bool? lateNightUsage,
    bool? doomScrollFlag,
    int? pickupCount,
    int? questionnaireScore,
  }) async {
    final payload = buildDemoPayload(
      screenTimeMinutes: screenTimeMinutes,
      unlockCount: unlockCount,
      socialMediaMinutes: socialMediaMinutes,
      sleepMinutes: sleepMinutes,
      questionnaireScore: questionnaireScore,
      exerciseMinutes: exerciseMinutes,
      restingHeartRate: restingHeartRate,
      lateNightUsage: lateNightUsage,
      doomScrollFlag: doomScrollFlag,
      pickupCount: pickupCount,
    );

    try {
      final url = Uri.parse(_backendUrl);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'stress_score': responseData['stress_score'] ?? 0,
          'stress_level': responseData['stress_level'] ?? 'Medium',
          'risk_level': responseData['risk_level'] ?? 'low',
          'confidence': responseData['confidence'] ?? 0.0,
          'contextual_message': responseData['ai_advice']
              ?? responseData['contextual_message']
              ?? '',
          'contributing_factors': responseData['contributing_factors'] ?? [],
          'actionable_tips': responseData['actionable_tips'] ?? [],
          'usage_score': responseData['usage_score'] ?? 0,
          'fitness_score': responseData['fitness_score'] ?? 0,
          'model_version': responseData['model_version'] ?? 'unknown',
          'timestamp': responseData['timestamp'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Backend returned status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Network Error: $e');
      return {
        'success': false,
        'error': 'Could not connect to AI Engine: $e',
      };
    }
  }

  /// Convenience: wraps the raw backend response into a StressAnalysis object
  /// so existing UI code that expects StressAnalysis still works.
  static Future<StressAnalysis?> analyzeAndWrap({
    int? socialMediaMinutes,
    int? sleepMinutes,
    int? screenTimeMinutes,
    int? unlockCount,
    int? exerciseMinutes,
    int? restingHeartRate,
    bool? lateNightUsage,
    bool? doomScrollFlag,
    int? pickupCount,
    int? questionnaireScore,
  }) async {
    final result = await analyzeStress(
      socialMediaMinutes: socialMediaMinutes,
      sleepMinutes: sleepMinutes,
      screenTimeMinutes: screenTimeMinutes,
      unlockCount: unlockCount,
      exerciseMinutes: exerciseMinutes,
      restingHeartRate: restingHeartRate,
      lateNightUsage: lateNightUsage,
      doomScrollFlag: doomScrollFlag,
      pickupCount: pickupCount,
      questionnaireScore: questionnaireScore,
    );

    if (result['success'] != true) return null;

    final score = (result['stress_score'] as num?)?.round() ?? 0;
    final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = (result['risk_level'] as String?) ?? 'low';
    final contextMsg = result['contextual_message'] as String?;

    // Parse contributing factors
    final rawFactors = result['contributing_factors'] as List<dynamic>? ?? [];
    final contribFactors = rawFactors
        .map((f) => ContributingFactor.fromJson(f as Map<String, dynamic>))
        .toList();

    // Parse actionable tips
    final rawTips = result['actionable_tips'] as List<dynamic>? ?? [];
    final tips = rawTips.map((t) => t.toString()).toList();

    // Parse sub-scores
    final usageScore = (result['usage_score'] as num?)?.round() ?? 0;
    final fitnessScore = (result['fitness_score'] as num?)?.round() ?? 0;

    return StressAnalysis(
      overallScore: score.clamp(0, 100),
      riskLevel: StressAnalysis.computeRiskLevel(score.clamp(0, 100)),
      questionnaireScore: questionnaireScore ?? -1,
      usageScore: usageScore,
      fitnessScore: fitnessScore,
      primaryFactor: contextMsg ?? 'Analysis powered by AI',
      factors: contribFactors.map((f) => f.detail).toList(),
      contributingFactors: contribFactors,
      actionableTips: tips,
      mlScore: score,
      mlConfidence: confidence,
      contextualMessage: contextMsg,
      mlEnhanced: true,
    );
  }
}

/// Notifier that holds the latest combined stress analysis.
class CombinedStressNotifier extends Notifier<StressAnalysis?> {
  @override
  StressAnalysis? build() => null;

  void update(StressAnalysis analysis) => state = analysis;
  void clear() => state = null;
}

final combinedStressProvider =
    NotifierProvider<CombinedStressNotifier, StressAnalysis?>(
        CombinedStressNotifier.new);
