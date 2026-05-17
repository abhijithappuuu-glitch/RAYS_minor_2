import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/widgets/app_page_route.dart';
import 'package:rakshak_ai/presentation/providers/scan_provider.dart';

/// Screen showing detailed mobile usage data with breakdown
class MobileUsageScreen extends ConsumerStatefulWidget {
  const MobileUsageScreen({super.key});

  @override
  ConsumerState<MobileUsageScreen> createState() => _MobileUsageScreenState();
}

class _MobileUsageScreenState extends ConsumerState<MobileUsageScreen> {
  String _selectedPeriod = 'Today';

  _UsageData _buildUsageFromScan(ScanResult scan) {
    final total = scan.usage.totalScreenMinutes;
    final social = scan.usage.socialMinutes;
    final unlocks = scan.usage.pickupCount;
    // Estimate category breakdown from total
    final entertainment = (total * 0.22).round();
    final productivity = (total * 0.18).round();
    final communication = (total * 0.13).round();
    final others = total - social - entertainment - productivity - communication;

    // Build hourly usage estimate based on current hour
    final hour = DateTime.now().hour;
    final hourlyUsage = List.generate(24, (i) {
      if (i > hour) return 0;
      if (i < 6) return 0;
      if (i < 9) return (total * 0.05).round();
      if (i < 12) return (total * 0.08).round();
      if (i < 15) return (total * 0.06).round();
      if (i < 18) return (total * 0.09).round();
      if (i < 21) return (total * 0.07).round();
      return (total * 0.03).round();
    });

    return _UsageData(
      totalMinutes: total,
      unlocks: unlocks,
      categories: [
        _AppCategory('Social Media', social, Icons.people, AppTheme.riskHigh),
        _AppCategory('Entertainment', entertainment, Icons.movie, AppTheme.riskMedium),
        _AppCategory('Productivity', productivity, Icons.work, AppTheme.riskLow),
        _AppCategory('Communication', communication, Icons.chat, AppTheme.primaryCyan),
        _AppCategory('Others', others.clamp(0, total), Icons.apps, AppTheme.textTertiary),
      ],
      hourlyUsage: hourlyUsage,
    );
  }

  _UsageData _emptyData() => _UsageData(
        totalMinutes: 0,
        unlocks: 0,
        categories: [],
        hourlyUsage: List.filled(24, 0),
      );

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    _UsageData data;
    if (scanState.hasScanned && scanState.lastScan != null) {
      final scan = scanState.lastScan!;
      final todayData = _buildUsageFromScan(scan);
      if (_selectedPeriod == 'This Week') {
        // Extrapolate weekly
        data = _UsageData(
          totalMinutes: todayData.totalMinutes * 7,
          unlocks: todayData.unlocks * 7,
          categories: todayData.categories
              .map((c) => _AppCategory(c.name, c.minutes * 7, c.icon, c.color))
              .toList(),
          hourlyUsage: todayData.hourlyUsage.map((v) => v * 7).toList(),
        );
      } else {
        data = todayData;
      }
    } else {
      data = _emptyData();
    }

    final hours = data.totalMinutes ~/ 60;
    final mins = data.totalMinutes % 60;
    final totalCatMinutes = data.categories.fold<int>(0, (s, c) => s + c.minutes);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Navigator.of(context).canPop()
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              title: const Text(
                'Mobile Usage',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),

            if (!scanState.hasScanned)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, size: 64, color: AppTheme.textTertiary),
                      const SizedBox(height: 16),
                      Text(
                        'No usage data yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Run a scan from the Home tab to see your usage data',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Period selector
                  Row(
                    children: ['Today', 'This Week'].map((p) {
                      final selected = _selectedPeriod == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: selected ? AppTheme.primaryGradient : null,
                              color: selected ? null : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: selected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Total usage card
                  SlideInWidget(
                    delay: const Duration(milliseconds: 80),
                    beginOffset: const Offset(0, 0.25),
                    child: GlassmorphicCard(
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.phone_android, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Screen Time',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${hours}h ${mins}m',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Icon(Icons.lock_open, color: AppTheme.primaryCyan, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '${data.unlocks}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'unlocks',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ), // SlideInWidget

                  const SizedBox(height: 24),

                  // Hourly heat bar
                  SlideInWidget(
                    delay: const Duration(milliseconds: 180),
                    beginOffset: const Offset(0, 0.25),
                    child: const Text(
                    'Usage by Hour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ),
                  const SizedBox(height: 12),
                  SlideInWidget(
                    delay: const Duration(milliseconds: 240),
                    beginOffset: const Offset(0, 0.25),
                    child: GlassmorphicCard(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(24, (i) {
                              final maxVal = data.hourlyUsage.reduce((a, b) => a > b ? a : b);
                              final h = maxVal > 0 ? (data.hourlyUsage[i] / maxVal) : 0.0;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Container(
                                    height: 6 + h * 70,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryCyan.withOpacity(0.3 + h * 0.7),
                                          AppTheme.accentPurple.withOpacity(0.3 + h * 0.7),
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['12AM', '6AM', '12PM', '6PM', '12AM']
                              .map((l) => Text(
                                    l,
                                    style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  ), // SlideInWidget hourly chart

                  const SizedBox(height: 24),

                  // App categories
                  const Text(
                    'App Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...data.categories.asMap().entries.map((entry) {
                    final catIdx = entry.key;
                    final cat = entry.value;
                    final pct = totalCatMinutes > 0
                        ? (cat.minutes / totalCatMinutes)
                        : 0.0;
                    final h = cat.minutes ~/ 60;
                    final m = cat.minutes % 60;
                    return SlideInWidget(
                      delay: Duration(milliseconds: 320 + catIdx * 65),
                      beginOffset: const Offset(0, 0.25),
                      child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassmorphicCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cat.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      backgroundColor: AppTheme.surfaceLight,
                                      valueColor: AlwaysStoppedAnimation(cat.color),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              h > 0 ? '${h}h ${m}m' : '${m}m',
                              style: TextStyle(
                                color: cat.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ), // SlideInWidget
                    );
                  }),

                  const SizedBox(height: 24),

                  // Impact on stress
                  SlideInWidget(
                    delay: const Duration(milliseconds: 640),
                    beginOffset: const Offset(0, 0.25),
                    child: GlassmorphicCard(
                    borderColor: AppTheme.riskMedium.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: AppTheme.riskMedium, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Impact on Stress',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data.totalMinutes > 300
                              ? 'Your screen time is above the recommended limit. High social media usage is directly correlated with increased stress. Try reducing by 30 minutes.'
                              : data.totalMinutes > 180
                                  ? 'Moderate screen time. Watch out for excessive social media scrolling sessions that can spike stress levels.'
                                  : 'Great job keeping screen time low! This positively impacts your stress levels.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ), // SlideInWidget impact card
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageData {
  final int totalMinutes;
  final int unlocks;
  final List<_AppCategory> categories;
  final List<int> hourlyUsage;

  _UsageData({
    required this.totalMinutes,
    required this.unlocks,
    required this.categories,
    required this.hourlyUsage,
  });
}

class _AppCategory {
  final String name;
  final int minutes;
  final IconData icon;
  final Color color;

  _AppCategory(this.name, this.minutes, this.icon, this.color);
}
