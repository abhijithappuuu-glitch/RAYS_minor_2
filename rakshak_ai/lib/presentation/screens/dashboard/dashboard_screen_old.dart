import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/widgets/stress_gauge.dart';
import 'package:rakshak_ai/presentation/widgets/risk_indicator.dart';
import 'package:rakshak_ai/presentation/widgets/insight_card.dart';
import 'package:rakshak_ai/presentation/providers/stress_provider.dart';
import 'package:rakshak_ai/presentation/screens/stress_check/stress_questionnaire_screen.dart';
import 'package:rakshak_ai/presentation/screens/fitness/fitness_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial stress calculation
    Future.microtask(() {
      ref.read(stressScoreProvider.notifier).calculateCurrentStress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stressState = ref.watch(stressScoreProvider);
    final behaviorAsync = ref.watch(userBehaviorProvider);

    // Extract values from providers with fallbacks
    final stressScore = stressState.when(
      data: (score) => score?.score ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final riskLevel = stressState.when(
      data: (score) => score?.riskLevel ?? 'low',
      loading: () => 'low',
      error: (_, __) => 'low',
    );

    final screenTimeHours = behaviorAsync.when(
      data: (b) => b.totalScreenMinutes / 60.0,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    // ignore: unused_local_variable
    final socialMinutes = behaviorAsync.when(
      data: (b) => b.socialMinutes,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // ignore: unused_local_variable
    final lateNight = behaviorAsync.when(
      data: (b) => b.lateNightUsage,
      loading: () => false,
      error: (_, __) => false,
    );

    // ignore: unused_local_variable
    final doomScroll = behaviorAsync.when(
      data: (b) => b.doomScrollFlag,
      loading: () => false,
      error: (_, __) => false,
    );

    // Default health values (will be replaced when health provider is wired)
    const sleepHours = 0.0;
    const exerciseMinutes = 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Evening',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(
                  left: AppTheme.spacingM,
                  bottom: AppTheme.spacingS,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () {},
                ),
              ],
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stress Gauge Section
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      children: [
                        Text(
                          'Your Stress Level',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        StressGauge(
                          score: stressScore,
                          riskLevel: riskLevel,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildStressInsight(context, riskLevel),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Health Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          icon: Icons.bedtime_outlined,
                          label: 'Sleep',
                          value: '${sleepHours}h',
                          color: sleepHours >= 7
                              ? AppTheme.riskLow
                              : AppTheme.riskMedium,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          icon: Icons.fitness_center_outlined,
                          label: 'Exercise',
                          value: '${exerciseMinutes}m',
                          color: exerciseMinutes >= 30
                              ? AppTheme.riskLow
                              : AppTheme.riskHigh,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Screen Time Card
                  _buildScreenTimeCard(context, screenTimeHours),

                  const SizedBox(height: AppTheme.spacingM),

                  // Quick Access
                  _buildQuickAccessSection(context),

                  const SizedBox(height: AppTheme.spacingM),

                  // Risk Indicators
                  _buildRiskIndicatorsSection(context),

                  const SizedBox(height: AppTheme.spacingM),

                  // Today's Insights
                  _buildInsightsSection(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickCard(
                context,
                icon: Icons.psychology,
                label: 'Stress Check',
                color: AppTheme.accentPurple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StressQuestionnaireScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildQuickCard(
                context,
                icon: Icons.fitness_center,
                label: 'Fitness',
                color: AppTheme.primaryCyan,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FitnessScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassmorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressInsight(BuildContext context, String riskLevel) {
    final messages = {
      'low': 'You\'re doing great! Keep up the healthy habits.',
      'medium': 'Some stress detected. Take a break and breathe.',
      'high': '⚠️ High stress levels. Consider relaxation techniques.',
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.getStressColor(riskLevel).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: AppTheme.getStressColor(riskLevel).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            riskLevel == 'high'
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            color: AppTheme.getStressColor(riskLevel),
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              messages[riskLevel] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeCard(BuildContext context, double hours) {
    final isExcessive = hours > 6;

    return GlassmorphicCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (isExcessive ? AppTheme.riskHigh : AppTheme.riskLow)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              Icons.phone_android,
              color: isExcessive ? AppTheme.riskHigh : AppTheme.riskLow,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screen Time Today',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours.toStringAsFixed(1)} hours',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isExcessive
                            ? AppTheme.riskHigh
                            : AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          if (isExcessive)
            const Icon(
              Icons.trending_up,
              color: AppTheme.riskHigh,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicatorsSection(BuildContext context) {
    final behaviorAsync = ref.watch(userBehaviorProvider);
    final lateNight = behaviorAsync.when(
      data: (b) => b.lateNightUsage,
      loading: () => false,
      error: (_, __) => false,
    );
    final doomScroll = behaviorAsync.when(
      data: (b) => b.doomScrollFlag,
      loading: () => false,
      error: (_, __) => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'Risk Indicators',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        RiskIndicator(
          icon: Icons.nightlight_round,
          title: 'Late Night Usage',
          subtitle: lateNight ? 'Active between 12-4 AM' : 'Not detected today',
          isActive: lateNight,
          severity: lateNight ? 'high' : 'low',
        ),
        const SizedBox(height: AppTheme.spacingS),
        RiskIndicator(
          icon: Icons.loop,
          title: 'Doom Scrolling',
          subtitle: doomScroll ? 'Extended social media session' : 'Not detected today',
          isActive: doomScroll,
          severity: doomScroll ? 'medium' : 'low',
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'Today\'s Insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        const InsightCard(
          icon: Icons.auto_awesome,
          title: 'Sleep Pattern Improving',
          description:
              'You\'ve slept consistently for 3 days. Great progress!',
          type: 'positive',
        ),
        const SizedBox(height: AppTheme.spacingS),
        const InsightCard(
          icon: Icons.warning_amber_rounded,
          title: 'Screen Time Alert',
          description: 'Your screen time is 40% higher than yesterday.',
          type: 'warning',
        ),
      ],
    );
  }
}
