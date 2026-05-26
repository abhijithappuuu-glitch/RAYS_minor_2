import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/widgets/app_page_route.dart';
import 'package:rakshak_ai/presentation/providers/scan_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('AI Insights'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Stress Heatmap
            SlideInWidget(
              delay: const Duration(milliseconds: 60),
              beginOffset: const Offset(0, 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Stress Trends', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildWeeklyHeatmap(scanState.history),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Behavior Correlation
            SlideInWidget(
              delay: const Duration(milliseconds: 160),
              beginOffset: const Offset(0, 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Behavior Correlation', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildCorrelationChart(),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Screen Time Analysis
            SlideInWidget(
              delay: const Duration(milliseconds: 260),
              beginOffset: const Offset(0, 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Screen Time Breakdown', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildScreenTimeBreakdown(scanState.lastScan),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Late Night Warnings
            SlideInWidget(
              delay: const Duration(milliseconds: 360),
              beginOffset: const Offset(0, 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Late Night Activity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildLateNightWarnings(scanState.lastScan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHeatmap(List<ScanResult> history) {
    final List<FlSpot> spots;
    if (history.isEmpty) {
      spots = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    } else {
      // Get the 7 most recent scans (or fewer), reversed so oldest is first
      final recent = history.take(7).toList().reversed.toList();
      spots = List.generate(7, (i) {
        if (i < recent.length) {
          final score = recent[i].analysis?.overallScore ?? 0;
          return FlSpot(i.toDouble(), score.toDouble());
        }
        return FlSpot(i.toDouble(), 0);
      });
    }

    return GlassmorphicCard(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Text(
                    days[value.toInt() % 7],
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryGold,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.3),
                    AppTheme.primaryGold.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  Widget _buildCorrelationChart() {
    return GlassmorphicCard(
      child: Column(
        children: [
          _buildCorrelationRow('Social Media', 0.75, AppTheme.riskHigh),
          _buildCorrelationRow('Sleep Quality', -0.60, AppTheme.riskLow),
          _buildCorrelationRow('Exercise', -0.45, AppTheme.riskLow),
          _buildCorrelationRow('Screen Time', 0.65, AppTheme.riskMedium),
        ],
      ),
    );
  }

  Widget _buildCorrelationRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.abs(),
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          SizedBox(
            width: 50,
            child: Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeBreakdown(ScanResult? lastScan) {
    final screenMins = lastScan?.usage.totalScreenMinutes ?? 0;
    final socialMins = lastScan?.usage.socialMinutes ?? 0;

    double socialPct = 35.0;
    double prodPct = 20.0;
    double otherPct = 45.0;

    if (screenMins > 0) {
      socialPct = (socialMins / screenMins) * 100;
      otherPct = 100 - socialPct - prodPct;
      if (otherPct < 0) otherPct = 5.0;
    }
    return GlassmorphicCard(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: socialPct,
                    title: '${socialPct.toInt()}%',
                    color: AppTheme.riskHigh,
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: otherPct * 0.4,
                    title: '${(otherPct * 0.4).toInt()}%',
                    color: AppTheme.riskMedium,
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: prodPct,
                    title: '${prodPct.toInt()}%',
                    color: AppTheme.primaryGold,
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: otherPct * 0.6,
                    title: '${(otherPct * 0.6).toInt()}%',
                    color: AppTheme.riskLow,
                    radius: 60,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Social', AppTheme.riskHigh),
              _buildLegendItem('Entertainment', AppTheme.riskMedium),
              _buildLegendItem('Productivity', AppTheme.primaryGold),
              _buildLegendItem('Other', AppTheme.riskLow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateNightWarnings(ScanResult? lastScan) {
    final hasLateNight = lastScan?.usage.lateNightUsage ?? false;
    
    if (!hasLateNight) {
      return GlassmorphicCard(
        borderColor: AppTheme.riskLow.withOpacity(0.3),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.riskLow,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'No late-night activity',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingM),
            Text(
              'Great job putting the phone away! This significantly improves sleep quality and reduces morning cortisol.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return GlassmorphicCard(
      borderColor: AppTheme.riskHigh.withOpacity(0.3),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.riskHigh,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  'Late-night session detected',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingM),
          Text(
            'Using your phone late at night disrupts circadian rhythm and increases stress. Try enabling Do Not Disturb after 11 PM.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
