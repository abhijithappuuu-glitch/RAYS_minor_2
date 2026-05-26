import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/providers/scan_provider.dart';
import 'package:rakshak_ai/presentation/widgets/app_page_route.dart';

class ScanHistoryScreen extends ConsumerWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final history = scanState.history;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            elevation: 0,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: const Text(
                'Scan History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            actions: [
              if (history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryCyan.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${history.length} scans',
                        style: const TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (history.isEmpty)
            // ── Empty State ──────────────────────────────────
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryCyan.withOpacity(0.08),
                        border: Border.all(
                            color: AppTheme.primaryCyan.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.history,
                          size: 48, color: AppTheme.primaryCyan),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No scans yet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Run your first scan from the Home tab\nto see results here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── History List ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final scan = history[index];
                    return SlideInWidget(
                      delay: Duration(milliseconds: 40 + index * 55),
                      beginOffset: const Offset(0, 0.25),
                      child: _ScanHistoryCard(
                        scan: scan,
                        index: index,
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Individual Scan Card ────────────────────────────────────────────────────

class _ScanHistoryCard extends StatelessWidget {
  final ScanResult scan;
  final int index;

  const _ScanHistoryCard({required this.scan, required this.index});

  @override
  Widget build(BuildContext context) {
    final analysis = scan.analysis;
    final riskLevel = analysis?.riskLevel.toLowerCase() ?? 'low';
    final stressScore = analysis?.overallScore ?? 0;
    final riskColor = AppTheme.getStressColor(riskLevel);
    final isToday = _isToday(scan.scannedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: index == 0
                ? riskColor.withOpacity(0.4)
                : AppTheme.glassBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ──────────────────────────────────
              Row(
                children: [
                  // Stress Score Circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          riskColor,
                          riskColor.withOpacity(0.2),
                        ],
                        stops: [stressScore / 100.0, stressScore / 100.0],
                      ),
                      border: Border.all(
                          color: riskColor.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$stressScore',
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _riskLabel(riskLevel),
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (index == 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Latest',
                                  style: TextStyle(
                                      color: AppTheme.primaryCyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            if (analysis?.mlEnhanced == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C47FF).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF6C47FF).withOpacity(0.4),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Text(
                                  'ML',
                                  style: TextStyle(
                                      color: Color(0xFF9E7BFF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isToday
                              ? 'Today · ${DateFormat('h:mm a').format(scan.scannedAt)}'
                              : DateFormat('EEE, MMM d · h:mm a')
                                  .format(scan.scannedAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Questionnaire indicator
                  if (scan.questionnaireScore != null)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology,
                          size: 16, color: AppTheme.accentPurple),
                    ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppTheme.glassBorder, height: 1),
              const SizedBox(height: 12),

              // ── Stats Row ───────────────────────────────────
              Row(
                children: [
                  _statChip(Icons.phone_android_outlined,
                      '${(scan.usage.totalScreenMinutes / 60).toStringAsFixed(1)}h',
                      'Screen'),
                  const SizedBox(width: 8),
                  _statChip(Icons.directions_walk, '${scan.fitness.steps}',
                      'Steps'),
                  const SizedBox(width: 8),
                  _statChip(Icons.bedtime_outlined,
                      '${scan.fitness.sleepHours.toStringAsFixed(1)}h',
                      'Sleep'),
                  const SizedBox(width: 8),
                  _statChip(Icons.favorite_outline,
                      scan.fitness.heartRate > 0
                          ? '${scan.fitness.heartRate}'
                          : '—',
                      'BPM'),
                ],
              ),

              // ── Contributing Factors ─────────────────────────
              if (analysis != null && analysis.factors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: analysis.factors
                      .take(3)
                      .map((f) => _factorChip(f, riskColor))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'high':
        return 'High Stress';
      case 'medium':
        return 'Moderate Stress';
      default:
        return 'Low Stress';
    }
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            Text(label,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _factorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }
}
