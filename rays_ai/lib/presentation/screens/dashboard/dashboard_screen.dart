import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/widgets/app_page_route.dart';
import 'package:rakshak_ai/presentation/providers/scan_provider.dart';
import 'package:rakshak_ai/presentation/providers/user_profile_provider.dart';
import 'package:rakshak_ai/presentation/screens/stress_check/stress_questionnaire_screen.dart';
import 'package:rakshak_ai/presentation/screens/fitness/fitness_screen.dart';
import 'package:rakshak_ai/presentation/screens/advice/advice_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak_ai/data/datasources/remote/stress_api_service.dart';
import 'package:rakshak_ai/core/di/injection.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanProvider);
    final profile = ref.watch(userProfileProvider);

    // Listen for questionnaire trigger
    ref.listen<ScanState>(scanProvider, (prev, next) {
      if (next.scanStatus == 'questionnaire' &&
          prev?.scanStatus != 'questionnaire') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showQuestionnaire(context);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: scan.isScanning
            ? KeyedSubtree(key: const ValueKey('scanning'), child: _buildScanningView(scan))
            : scan.hasScanned && scan.lastScan != null
                ? KeyedSubtree(key: const ValueKey('data'), child: _buildDataView(scan, profile))
                : KeyedSubtree(key: const ValueKey('empty'), child: _buildEmptyView(profile)),
      ),
    );
  }

  Future<void> _showQuestionnaire(BuildContext context) async {
    // Clear status first so it doesn't re-trigger
    ref.read(scanProvider.notifier).clearScanStatus();

    final score = await Navigator.of(context).push<int>(
      SlideUpPageRoute(
        builder: (_) => const StressQuestionnaireScreen(returnScore: true),
      ),
    );

    // Finalize with score (or null if user skipped/backed out)
    if (context.mounted) {
      await ref.read(scanProvider.notifier).finalizeWithQuestionnaire(score);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  EMPTY STATE — First time, no data
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyView(UserProfile profile) {
    final name = profile.isComplete ? profile.name.split(' ').first : 'there';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Greeting
            Text(
              'Hi $name! 👋',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryCyan,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const Spacer(flex: 1),

            // Empty illustration
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryCyan.withOpacity(0.15 + _pulseController.value * 0.1),
                        AppTheme.accentPurple.withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withOpacity(0.1 + _pulseController.value * 0.08),
                        blurRadius: 30 + _pulseController.value * 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 70,
                    color: AppTheme.primaryCyan,
                  ),
                );
              },
            ),

            const Spacer(flex: 1),

            Text(
              'Ready to check your wellness?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Tap below to scan your mobile usage, fitness data, and analyze your stress levels.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 1),

            // Big scan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(scanProvider.notifier).startScan();
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  'Start Scan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryCyan.withOpacity(0.4),
                ),
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SCANNING VIEW — Animated progress
  // ═══════════════════════════════════════════════════════════
  Widget _buildScanningView(ScanState scan) {
    final statusLabel = switch (scan.scanStatus) {
      'usage' => 'Reading phone usage data...',
      'fitness' => 'Syncing Google Fit data...',
      'analyzing' => 'Analysing your wellness...',
      _ => 'Preparing scan...',
    };

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated scanner ring
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(150, 150),
                        painter: _ScanRingPainter(
                          progress: _pulseController.value,
                          color: AppTheme.primaryCyan,
                        ),
                      );
                    },
                  ),
                  Icon(
                    scan.scanStatus == 'usage'
                        ? Icons.phone_android
                        : scan.scanStatus == 'fitness'
                            ? Icons.favorite
                            : Icons.psychology,
                    size: 50,
                    color: AppTheme.primaryCyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryCyan,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.surfaceLight,
                color: AppTheme.primaryCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DATA VIEW — After scan, with floating stress gauge
  // ═══════════════════════════════════════════════════════════
  Widget _buildDataView(ScanState scan, UserProfile profile) {
    final result = scan.lastScan!;
    final analysis = result.analysis;
    final stressScore = analysis?.overallScore ?? 0;
    final riskLevel = analysis?.riskLevel.toLowerCase() ?? 'low';
    final usage = result.usage;
    final fitness = result.fitness;
    final name = profile.isComplete ? profile.name.split(' ').first : '';
    final greeting = profile.isComplete ? profile.greeting : 'Good Evening';
    final screenHours = usage.totalScreenMinutes / 60.0;
    final socialHours = usage.socialMinutes / 60.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Floating Header with Stress Gauge ──
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.getStressColor(riskLevel).withOpacity(0.12),
                  AppTheme.backgroundDark,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: greeting + rescan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? '$greeting, $name' : greeting,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d').format(DateTime.now()),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                ref.read(scanProvider.notifier).startScan();
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              color: AppTheme.primaryCyan,
                              tooltip: 'Rescan',
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Floating Stress Gauge ──
                    Center(
                      child: _FloatingStressGauge(
                        score: stressScore,
                        riskLevel: riskLevel,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stress insight bar
                    _buildStressInsight(context, riskLevel, stressScore,
                        mlEnhanced: analysis?.mlEnhanced ?? false,
                        contextualMessage: analysis?.contextualMessage),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Scrollable Content ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // ── Quick Stats Row ──
              SlideInWidget(
                delay: const Duration(milliseconds: 60),
                beginOffset: const Offset(0, 0.3),
                child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.bedtime_outlined,
                      label: 'Sleep',
                      value: '${fitness.sleepHours.toStringAsFixed(1)}h',
                      color: fitness.sleepHours >= 7
                          ? AppTheme.riskLow
                          : fitness.sleepHours >= 5
                              ? AppTheme.riskMedium
                              : AppTheme.riskHigh,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: '${fitness.steps}',
                      color: fitness.steps >= 8000
                          ? AppTheme.riskLow
                          : fitness.steps >= 4000
                              ? AppTheme.riskMedium
                              : AppTheme.riskHigh,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite_outline,
                      label: 'BPM',
                      value: '${fitness.heartRate}',
                      color: fitness.heartRate <= 80
                          ? AppTheme.riskLow
                          : AppTheme.riskMedium,
                    ),
                  ),
                ],
              ),
              ),

              const SizedBox(height: 16),

              // ── Screen Time Card ──
              SlideInWidget(
                delay: const Duration(milliseconds: 140),
                beginOffset: const Offset(0, 0.3),
                child: _buildScreenTimeCard(screenHours, socialHours, usage.pickupCount),
              ),

              const SizedBox(height: 12),

              // ── Exercise + Calories Row ──
              SlideInWidget(
                delay: const Duration(milliseconds: 220),
                beginOffset: const Offset(0, 0.3),
                child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.fitness_center,
                      label: 'Exercise',
                      value: '${fitness.exerciseMinutes}m',
                      color: fitness.exerciseMinutes >= 30
                          ? AppTheme.riskLow
                          : AppTheme.riskHigh,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Calories',
                      value: '${fitness.caloriesBurned}',
                      color: AppTheme.riskMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Water',
                      value: '${fitness.waterGlasses}/8',
                      color: fitness.waterGlasses >= 6
                          ? AppTheme.riskLow
                          : AppTheme.riskMedium,
                    ),
                  ),
                ],
              ),
              ),

              const SizedBox(height: 16),

              // ── Quick Actions ──
              SlideInWidget(
                delay: const Duration(milliseconds: 300),
                beginOffset: const Offset(0, 0.3),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.psychology,
                      label: 'Stress Check',
                      color: AppTheme.accentPurple,
                      onTap: () async {
                        final score = await Navigator.of(context).push<int>(
                          SlideUpPageRoute(
                            builder: (_) => const StressQuestionnaireScreen(returnScore: true),
                          ),
                        );
                        if (score != null) {
                          ref.read(scanProvider.notifier).updateQuestionnaireScore(score);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.fitness_center,
                      label: 'Fitness',
                      color: AppTheme.primaryCyan,
                      onTap: () => Navigator.of(context).push(
                        AppPageRoute(builder: (_) => FitnessScreen(fitnessData: fitness)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.lightbulb_outline,
                      label: 'Advice',
                      color: AppTheme.riskMedium,
                      onTap: () => Navigator.of(context).push(
                        AppPageRoute(
                          builder: (_) => AdviceScreen(
                            stressScore: stressScore,
                            riskLevel: riskLevel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
              ),

              const SizedBox(height: 16),

              // ── Risk Indicators ──
              if (usage.lateNightUsage || usage.doomScrollFlag) ...[
                Text(
                  'Risk Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (usage.lateNightUsage)
                  _buildRiskAlert(
                    Icons.nightlight_round,
                    'Late Night Usage',
                    'Phone used between 12–4 AM',
                    AppTheme.riskHigh,
                  ),
                if (usage.doomScrollFlag)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildRiskAlert(
                      Icons.loop,
                      'Doom Scrolling',
                      'Extended social media session (>${(usage.socialMinutes / 60).toStringAsFixed(1)}h)',
                      AppTheme.riskMedium,
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // ── Analysis Breakdown ──
              if (analysis != null) ...[
                Text(
                  'Stress Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                GlassmorphicCard(
                  child: Column(
                    children: [
                      _buildBreakdownRow(
                        'Questionnaire',
                        analysis.questionnaireScore >= 0
                            ? analysis.questionnaireScore
                            : null,
                        AppTheme.accentPurple,
                        '40%',
                      ),
                      const SizedBox(height: 10),
                      _buildBreakdownRow(
                        'Mobile Usage',
                        analysis.usageScore,
                        AppTheme.riskMedium,
                        '30%',
                      ),
                      const SizedBox(height: 10),
                      _buildBreakdownRow(
                        'Fitness Data',
                        analysis.fitnessScore,
                        AppTheme.primaryCyan,
                        '30%',
                      ),
                      if (analysis.factors.isNotEmpty) ...[
                        const Divider(color: AppTheme.glassBorder, height: 24),
                        ...analysis.factors.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 14, color: AppTheme.textTertiary),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],

              // ── AI Feedback Loop ──
              SlideInWidget(
                delay: const Duration(milliseconds: 350),
                beginOffset: const Offset(0, 0.3),
                child: _buildFeedbackCard(),
              ),

              // Scanned at footer
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Last scanned ${DateFormat('h:mm a').format(result.scannedAt)}',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ──────────────────────────────────────

  Widget _buildStressInsight(
      BuildContext context, String riskLevel, int score,
      {bool mlEnhanced = false, String? contextualMessage}) {
    final defaultMsg = switch (riskLevel) {
      'high' => 'Your stress indicators are elevated. Prioritize relaxation.',
      'medium' => 'You are carrying moderate stress today. Remember to take breaks.',
      _ => 'You are maintaining a great balance today! Keep it up.',
    };

    final displayMsg = contextualMessage ?? defaultMsg;
    
    // Create a beautiful, soothing gradient based on risk level
    final Color baseColor = riskLevel == 'high' 
        ? const Color(0xFFFF5E5E) 
        : riskLevel == 'medium' 
            ? const Color(0xFFFFB03A) 
            : const Color(0xFF32D74B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(0.15),
            baseColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: baseColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: baseColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI INSIGHT',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (mlEnhanced)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C47FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6C47FF).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.blur_on, color: Color(0xFF9E7BFF), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'POWERED BY ML',
                        style: TextStyle(
                            color: Color(0xFF9E7BFF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayMsg,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            color: AppTheme.accentPurple,
            size: 28,
          ),
          const SizedBox(height: 12),
          const Text(
            'How are you actually feeling?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help our AI learn your personal baseline by sharing your current mood.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodEmoji('😢', 5, 'Stressed'),
              _buildMoodEmoji('😐', 3, 'Okay'),
              _buildMoodEmoji('😊', 1, 'Great'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEmoji(String emoji, int stressLevel, String label) {
    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final deviceId = prefs.getString('device_id') ?? 'unknown';
        try {
          await getIt<StressApiService>().submitFeedback(
            deviceId: deviceId,
            reportedStressLevel: stressLevel,
            context: 'Dashboard Quick Feedback',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thanks! This helps personalize your insights.'),
                backgroundColor: AppTheme.primaryCyan,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(double hours, double socialHours, int pickups) {
    final isExcessive = hours > 6;

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isExcessive ? AppTheme.riskHigh : AppTheme.riskLow)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: isExcessive ? AppTheme.riskHigh : AppTheme.riskLow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Screen Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(
                      '${hours.toStringAsFixed(1)} hours',
                      style: TextStyle(
                        color: isExcessive ? AppTheme.riskHigh : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExcessive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.riskHigh.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('HIGH', style: TextStyle(color: AppTheme.riskHigh, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Social', '${socialHours.toStringAsFixed(1)}h', AppTheme.riskHigh),
              const SizedBox(width: 16),
              _buildMiniStat('Pickups', '$pickups', AppTheme.riskMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassmorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAlert(IconData icon, String title, String subtitle, Color color) {
    return GlassmorphicCard(
      backgroundColor: color.withOpacity(0.05),
      borderColor: color.withOpacity(0.2),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int? score, Color color, String weight) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
        if (score != null)
          Text('$score/100', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))
        else
          const Text('Not taken', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
        const SizedBox(width: 8),
        Text(weight, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Floating Stress Gauge Widget
// ═══════════════════════════════════════════════════════════════
class _FloatingStressGauge extends StatefulWidget {
  final int score;
  final String riskLevel;

  const _FloatingStressGauge({required this.score, required this.riskLevel});

  @override
  State<_FloatingStressGauge> createState() => _FloatingStressGaugeState();
}

class _FloatingStressGaugeState extends State<_FloatingStressGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: 0, end: widget.score / 100.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FloatingStressGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(begin: _anim.value, end: widget.score / 100.0)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStressColor(widget.riskLevel);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final displayScore = (_anim.value * 100).round();
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _FloatingGaugePainter(
                progress: _anim.value,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$displayScore',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.riskLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _FloatingGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const stroke = 10.0;

    // BG ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = AppTheme.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.75,
          endAngle: -math.pi * 0.75 + math.pi * 1.5 * progress,
          colors: [color.withOpacity(0.4), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Glow
    canvas.drawArc(
      rect,
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_FloatingGaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _ScanRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Spinning arc
    final sweep = math.pi * 0.8;
    final startAngle = math.pi * 2 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_ScanRingPainter old) => old.progress != progress;
}
