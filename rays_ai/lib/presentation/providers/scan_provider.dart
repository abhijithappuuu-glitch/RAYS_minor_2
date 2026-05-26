import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak_ai/core/di/injection.dart';
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
        // Persist backend analysis results
        if (analysis != null) ...{
          'analysisScore': analysis!.overallScore,
          'analysisRisk': analysis!.riskLevel,
          'analysisMsg': analysis!.contextualMessage ?? '',
          'analysisConfidence': analysis!.mlConfidence ?? 0.0,
          'analysisMlEnhanced': analysis!.mlEnhanced,
          'usageScore': analysis!.usageScore,
          'fitnessScore': analysis!.fitnessScore,
          'factors': analysis!.factors,
          'contributingFactors': analysis!.contributingFactors.map((f) => {'name': f.name, 'detail': f.detail, 'severity': f.severity}).toList(),
          'actionableTips': analysis!.actionableTips,
        },
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

    // Restore persisted backend analysis (no local recalculation)
    StressAnalysis? analysis;
    if (j['analysisScore'] != null) {
      final score = (j['analysisScore'] as num).round();
      final rawFactors = j['contributingFactors'] as List<dynamic>? ?? [];
      final contribFactors = rawFactors
          .map((f) => ContributingFactor.fromJson(f as Map<String, dynamic>))
          .toList();
      
      analysis = StressAnalysis(
        overallScore: score,
        riskLevel: StressAnalysis.computeRiskLevel(score),
        questionnaireScore: qScore ?? -1,
        usageScore: (j['usageScore'] as num?)?.round() ?? 0,
        fitnessScore: (j['fitnessScore'] as num?)?.round() ?? 0,
        primaryFactor: (j['analysisMsg'] as String?) ?? '',
        factors: (j['factors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        contributingFactors: contribFactors,
        actionableTips: (j['actionableTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        mlScore: score,
        mlConfidence: (j['analysisConfidence'] as num?)?.toDouble() ?? 0.0,
        contextualMessage: (j['analysisMsg'] as String?) ?? '',
        mlEnhanced: (j['analysisMlEnhanced'] as bool?) ?? true,
      );
    }

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

  // ── Main Scan — Collects data then sends to Python backend ───────────────

  Future<void> startScan() async {
    state = state.copyWith(
      isScanning: true,
      scanStatus: 'usage',
      scanError: null,
    );

    // ── Step 1: Collect Mobile Usage Stats ─────────────────────
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

    // ── Step 2: Collect Fitness / Google Fit Data ──────────────
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

    // ── Step 3: Send ALL data to Python backend ───────────────
    // NO local scoring. Python is the single source of truth.
    final analysis = await StressAnalysisEngine.analyzeAndWrap(
      socialMediaMinutes: usage.socialMinutes,
      sleepMinutes: (fitness.sleepHours * 60).round(),
      screenTimeMinutes: usage.totalScreenMinutes,
      unlockCount: usage.pickupCount,
      exerciseMinutes: fitness.exerciseMinutes,
      restingHeartRate: fitness.heartRate,
      lateNightUsage: usage.lateNightUsage,
      doomScrollFlag: usage.doomScrollFlag,
      pickupCount: usage.pickupCount,
    );

    final scanResult = ScanResult(
      usage: usage,
      fitness: fitness,
      analysis: analysis,
      scannedAt: DateTime.now(),
    );

    // Most recent first; keep max 50 records
    final updatedHistory =
        [scanResult, ...state.history].take(50).toList();

    state = state.copyWith(
      isScanning: false,
      hasScanned: true,
      lastScan: scanResult,
      scanStatus: analysis != null ? 'done' : '',
      scanError: analysis == null ? 'Could not connect to AI Engine' : null,
      history: updatedHistory,
    );

    await _persistHistory(updatedHistory);
  }

  /// Called after user completes OR skips the questionnaire.
  /// Re-sends to backend with questionnaire score included.
  Future<void> finalizeWithQuestionnaire(int? questionnaireScore) async {
    final scan = state.lastScan;
    if (scan == null) return;

    // Re-analyze with questionnaire score via backend
    final analysis = await StressAnalysisEngine.analyzeAndWrap(
      socialMediaMinutes: scan.usage.socialMinutes,
      sleepMinutes: (scan.fitness.sleepHours * 60).round(),
      screenTimeMinutes: scan.usage.totalScreenMinutes,
      unlockCount: scan.usage.pickupCount,
      exerciseMinutes: scan.fitness.exerciseMinutes,
      restingHeartRate: scan.fitness.heartRate,
      lateNightUsage: scan.usage.lateNightUsage,
      doomScrollFlag: scan.usage.doomScrollFlag,
      pickupCount: scan.usage.pickupCount,
      questionnaireScore: questionnaireScore,
    );

    // Use new result if backend succeeded, otherwise keep the existing one
    final finalAnalysis = analysis ?? scan.analysis;

    final finalResult = ScanResult(
      usage: scan.usage,
      fitness: scan.fitness,
      questionnaireScore: questionnaireScore,
      analysis: finalAnalysis,
      scannedAt: scan.scannedAt,
    );

    // Most recent first; keep max 50 records
    final updatedHistory =
        [finalResult, ...state.history.skip(1)].take(50).toList();

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
