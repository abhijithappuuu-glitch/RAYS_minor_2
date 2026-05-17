import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/data/datasources/remote/stress_api_service.dart';
import 'package:rakshak_ai/domain/entities/user_behavior.dart';
import 'package:rakshak_ai/domain/repositories/usage_repository.dart';
import 'package:rakshak_ai/domain/repositories/health_repository.dart';
import 'package:rakshak_ai/features/stress_analysis/stress_analysis_engine.dart';

/// Fitness data snapshot
class FitnessSnapshot {
  final int steps;
  final int heartRate;
  final double sleepHours;
  final int exerciseMinutes;
  final int caloriesBurned;
  final int waterGlasses;

  const FitnessSnapshot({
    this.steps = 0,
    this.heartRate = 0,
    this.sleepHours = 0,
    this.exerciseMinutes = 0,
    this.caloriesBurned = 0,
    this.waterGlasses = 0,
  });

  factory FitnessSnapshot.empty() => const FitnessSnapshot();

  Map<String, dynamic> toJson() => {
        'steps': steps,
        'heartRate': heartRate,
        'sleepHours': sleepHours,
        'exerciseMinutes': exerciseMinutes,
        'caloriesBurned': caloriesBurned,
        'waterGlasses': waterGlasses,
      };

  factory FitnessSnapshot.fromJson(Map<String, dynamic> j) => FitnessSnapshot(
        steps: (j['steps'] as int?) ?? 0,
        heartRate: (j['heartRate'] as int?) ?? 0,
        sleepHours: (j['sleepHours'] as num?)?.toDouble() ?? 0,
        exerciseMinutes: (j['exerciseMinutes'] as int?) ?? 0,
        caloriesBurned: (j['caloriesBurned'] as int?) ?? 0,
        waterGlasses: (j['waterGlasses'] as int?) ?? 0,
      );
}

/// Holds all scanned data from a single scan session
class ScanResult {
  final UserBehavior usage;
  final FitnessSnapshot fitness;
  final int? questionnaireScore;
  final StressAnalysis? analysis;
  final DateTime scannedAt;

  const ScanResult({
    required this.usage,
    required this.fitness,
    this.questionnaireScore,
    this.analysis,
    required this.scannedAt,
  });

  bool get hasData => usage.totalScreenMinutes > 0 || fitness.steps > 0;

  Map<String, dynamic> toJson() => {
        'scannedAt': scannedAt.toIso8601String(),
        'screenMins': usage.totalScreenMinutes,
        'socialMins': usage.socialMinutes,
        'pickups': usage.pickupCount,
        'lateNight': usage.lateNightUsage,
        'doomScroll': usage.doomScrollFlag,
        'steps': fitness.steps,
        'heartRate': fitness.heartRate,
        'sleepHours': fitness.sleepHours,
        'exerciseMins': fitness.exerciseMinutes,
        'calories': fitness.caloriesBurned,
        'water': fitness.waterGlasses,
        if (questionnaireScore != null) 'qScore': questionnaireScore,
      };

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final usage = UserBehavior(
      totalScreenMinutes: (j['screenMins'] as int?) ?? 0,
      socialMinutes: (j['socialMins'] as int?) ?? 0,
      pickupCount: (j['pickups'] as int?) ?? 0,
      lateNightUsage: (j['lateNight'] as bool?) ?? false,
      doomScrollFlag: (j['doomScroll'] as bool?) ?? false,
      timestamp:
          DateTime.tryParse(j['scannedAt'] as String? ?? '') ?? DateTime.now(),
    );
    final fitness = FitnessSnapshot(
      steps: (j['steps'] as int?) ?? 0,
      heartRate: (j['heartRate'] as int?) ?? 0,
      sleepHours: (j['sleepHours'] as num?)?.toDouble() ?? 0,
      exerciseMinutes: (j['exerciseMins'] as int?) ?? 0,
      caloriesBurned: (j['calories'] as int?) ?? 0,
      waterGlasses: (j['water'] as int?) ?? 0,
    );
    final qScore = j['qScore'] as int?;
    final analysis = StressAnalysisEngine.analyze(
      questionnaireScore: qScore,
      screenTimeHours: usage.totalScreenMinutes / 60.0,
      socialMediaHours: usage.socialMinutes / 60.0,
      unlocks: usage.pickupCount,
      lateNightUsage: usage.lateNightUsage,
      steps: fitness.steps,
      sleepHours: fitness.sleepHours,
      exerciseMinutes: fitness.exerciseMinutes,
      heartRate: fitness.heartRate,
    );
    return ScanResult(
      usage: usage,
      fitness: fitness,
      questionnaireScore: qScore,
      analysis: analysis,
      scannedAt:
          DateTime.tryParse(j['scannedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// App-wide scan state
class ScanState {
  final bool isScanning;
  final bool hasScanned;
  final ScanResult? lastScan;
  /// '' | 'usage' | 'fitness' | 'analyzing' | 'questionnaire' | 'done'
  final String scanStatus;
  final String? scanError;
  final List<ScanResult> history;

  const ScanState({
    this.isScanning = false,
    this.hasScanned = false,
    this.lastScan,
    this.scanStatus = '',
    this.scanError,
    this.history = const [],
  });

  ScanState copyWith({
    bool? isScanning,
    bool? hasScanned,
    ScanResult? lastScan,
    String? scanStatus,
    String? scanError,
    List<ScanResult>? history,
  }) =>
      ScanState(
        isScanning: isScanning ?? this.isScanning,
        hasScanned: hasScanned ?? this.hasScanned,
        lastScan: lastScan ?? this.lastScan,
        scanStatus: scanStatus ?? this.scanStatus,
        scanError: scanError,
        history: history ?? this.history,
      );
}

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    _loadPersistedData();
    return const ScanState();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('scan_history_v2');
    final List<ScanResult> history = [];
    if (historyJson != null) {
      try {
        final raw = json.decode(historyJson) as List<dynamic>;
        for (final item in raw) {
          try {
            history.add(ScanResult.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (history.isNotEmpty) {
      state = ScanState(
        hasScanned: true,
        lastScan: history.first,
        history: history,
      );
    } else {
      state = ScanState(history: history);
    }
  }

  Future<void> _persistHistory(List<ScanResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'scan_history_v2',
      json.encode(history.map((r) => r.toJson()).toList()),
    );
  }

  // ── Main Scan — Real device data only ────────────────────────────────────

  Future<void> startScan() async {
    state = state.copyWith(
      isScanning: true,
      scanStatus: 'usage',
      scanError: null,
    );

    // ── Step 1: Real Mobile Usage Stats ──────────────────────
    UserBehavior usage;
    try {
      final usageRepo = getIt<UsageRepository>();
      final hasUsagePerm = await usageRepo.hasUsagePermission();
      if (!hasUsagePerm) {
        await usageRepo.requestUsagePermission();
        await Future.delayed(const Duration(seconds: 1));
      }
      usage = await usageRepo.getUsageStats();
    } catch (_) {
      usage = UserBehavior(
        totalScreenMinutes: 0,
        socialMinutes: 0,
        pickupCount: 0,
        lateNightUsage: false,
        doomScrollFlag: false,
        timestamp: DateTime.now(),
      );
    }

    state = state.copyWith(scanStatus: 'fitness');
    await Future.delayed(const Duration(milliseconds: 400));

    // ── Step 2: Real Fitness / Google Fit Data ───────────────
    FitnessSnapshot fitness;
    try {
      final healthRepo = getIt<HealthRepository>();
      final hasPerm = await healthRepo.hasHealthPermissions();
      if (!hasPerm) {
        await healthRepo.requestHealthPermissions();
        await Future.delayed(const Duration(seconds: 1));
      }
      final healthData = await healthRepo.getHealthData();
      fitness = FitnessSnapshot(
        steps: healthData.steps ?? 0,
        heartRate: healthData.restingHeartRate ?? 0,
        sleepHours: (healthData.sleepMinutes ?? 0) / 60.0,
        exerciseMinutes: healthData.exerciseMinutes ?? 0,
        caloriesBurned: 0,
        waterGlasses: 0,
      );
    } catch (_) {
      fitness = FitnessSnapshot.empty();
    }

    state = state.copyWith(scanStatus: 'analyzing');
    await Future.delayed(const Duration(milliseconds: 400));

    // ── Step 3: Partial Analysis (questionnaire pending) ─────
    final analysis = StressAnalysisEngine.analyze(
      questionnaireScore: null,
      screenTimeHours: usage.totalScreenMinutes / 60.0,
      socialMediaHours: usage.socialMinutes / 60.0,
      unlocks: usage.pickupCount,
      lateNightUsage: usage.lateNightUsage,
      steps: fitness.steps,
      sleepHours: fitness.sleepHours,
      exerciseMinutes: fitness.exerciseMinutes,
      heartRate: fitness.heartRate,
    );

    final partialResult = ScanResult(
      usage: usage,
      fitness: fitness,
      analysis: analysis,
      scannedAt: DateTime.now(),
    );

    // Signal questionnaire should now be shown
    state = state.copyWith(
      isScanning: false,
      hasScanned: true,
      lastScan: partialResult,
      scanStatus: 'questionnaire',
    );
  }

  /// Called after user completes OR skips the questionnaire.
  /// Finalises the scan with optional questionnaire score and saves to history.
  /// Always runs local heuristic analysis first, then attempts to enhance the
  /// score with the backend ML model. Backend errors are silently ignored so
  /// the app works fully offline.
  Future<void> finalizeWithQuestionnaire(int? questionnaireScore) async {
    final scan = state.lastScan;
    if (scan == null) return;

    // ── Step 1: local heuristic analysis ──────────────────────────
    var analysis = StressAnalysisEngine.analyze(
      questionnaireScore: questionnaireScore,
      screenTimeHours: scan.usage.totalScreenMinutes / 60.0,
      socialMediaHours: scan.usage.socialMinutes / 60.0,
      unlocks: scan.usage.pickupCount,
      lateNightUsage: scan.usage.lateNightUsage,
      steps: scan.fitness.steps,
      sleepHours: scan.fitness.sleepHours,
      exerciseMinutes: scan.fitness.exerciseMinutes,
      heartRate: scan.fitness.heartRate,
    );

    // ── Step 2: ML backend enhancement (best-effort) ───────────────
    try {
      final mlResponse = await getIt<StressApiService>().predictStress({
        'social_minutes': scan.usage.socialMinutes,
        'late_night_usage': scan.usage.lateNightUsage,
        'sleep_minutes': (scan.fitness.sleepHours * 60).round(),
        'doom_scroll_flag': scan.usage.doomScrollFlag,
        'pickup_count': scan.usage.pickupCount,
        'exercise_minutes': scan.fitness.exerciseMinutes,
        'resting_heart_rate': scan.fitness.heartRate,
      });

      final mlScore = (mlResponse['stress_score'] as num?)?.round();
      final mlConf  = (mlResponse['confidence'] as num?)?.toDouble() ?? 1.0;

      if (mlScore != null) {
        analysis = analysis.copyWithMl(
          mlScore: mlScore.clamp(0, 100),
          mlConfidence: mlConf,
        );
      }
    } catch (_) {
      // Backend unavailable or returned unexpected data — keep local score
    }

    final finalResult = ScanResult(
      usage: scan.usage,
      fitness: scan.fitness,
      questionnaireScore: questionnaireScore,
      analysis: analysis,
      scannedAt: scan.scannedAt,
    );

    // Most recent first; keep max 50 records
    final updatedHistory =
        [finalResult, ...state.history].take(50).toList();

    state = state.copyWith(
      lastScan: finalResult,
      hasScanned: true,
      scanStatus: 'done',
      history: updatedHistory,
    );

    await _persistHistory(updatedHistory);
  }

  /// Quick-update questionnaire on an already-saved scan (from Quick Actions)
  Future<void> updateQuestionnaireScore(int score) async {
    await finalizeWithQuestionnaire(score);
  }

  /// Consume questionnaire prompt signal
  void clearScanStatus() {
    state = state.copyWith(scanStatus: '');
  }
}

final scanProvider =
    NotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);
