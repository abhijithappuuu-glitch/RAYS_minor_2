import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/core/security/encryption_service.dart';
import 'package:rakshak_ai/core/security/root_detection.dart';
import 'package:rakshak_ai/core/error/error_handler.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/features/background_monitoring/adaptive_scheduler.dart';
import 'package:rakshak_ai/features/smart_notifications/intervention_engine.dart';
import 'package:rakshak_ai/presentation/providers/settings_provider.dart';
import 'package:rakshak_ai/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:rakshak_ai/presentation/screens/insights/insights_screen.dart';
import 'package:rakshak_ai/presentation/screens/privacy/privacy_screen.dart';
import 'package:rakshak_ai/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:rakshak_ai/presentation/screens/usage/mobile_usage_screen.dart';
import 'package:rakshak_ai/presentation/screens/history/scan_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar for immersive feel
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.backgroundDark,
  ));

  // ── Security Checks ──────────────────────────────────
  final isRooted = await RootDetectionService.isDeviceRooted();
  if (isRooted) {
    ErrorHandler.logWarning('Device may be rooted — running with caution');
  }

  // ── Dependency Injection ─────────────────────────────
  await configureDependencies();

  // ── Initialize Core Services ─────────────────────────
  await getIt<EncryptionService>().initialize();
  await getIt<AdaptiveScheduler>().initialize();
  await getIt<InterventionEngine>().initialize();

  // ── Schedule Background Monitoring ───────────────────
  await getIt<AdaptiveScheduler>().scheduleMonitoring('NORMAL');

  runApp(
    const ProviderScope(
      child: RaysApp(),
    ),
  );
}

class RaysApp extends ConsumerStatefulWidget {
  const RaysApp({super.key});

  @override
  ConsumerState<RaysApp> createState() => _RaysAppState();
}

class _RaysAppState extends ConsumerState<RaysApp> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    setState(() {
      _showOnboarding = !completed;
      _isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch dark mode — rebuilds MaterialApp whenever the setting changes
    final isDark = ref.watch(settingsProvider.select((s) => s.darkModeEnabled));

    // Keep status/nav bar style in sync with theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppTheme.backgroundDark : AppTheme.lightBackground,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'RAYS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: _isLoading
          ? Scaffold(
              backgroundColor: isDark
                  ? AppTheme.backgroundDark
                  : AppTheme.lightBackground,
              body: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryCyan),
              ),
            )
          : _showOnboarding
              ? OnboardingScreen(onComplete: _completeOnboarding)
              : const RaysHome(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item descriptor
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const _navItems = [
  _NavItem(icon: Icons.home_outlined,         activeIcon: Icons.home_rounded,       label: 'Home'),
  _NavItem(icon: Icons.phone_android_outlined, activeIcon: Icons.phone_android,      label: 'Usage'),
  _NavItem(icon: Icons.insights_outlined,      activeIcon: Icons.insights,           label: 'Insights'),
  _NavItem(icon: Icons.history_outlined,       activeIcon: Icons.history,            label: 'History'),
  _NavItem(icon: Icons.settings_outlined,      activeIcon: Icons.settings,           label: 'Settings'),
];

// ─────────────────────────────────────────────────────────────────────────────
// RaysHome — PageView + animated frosted bottom nav
// ─────────────────────────────────────────────────────────────────────────────
class RaysHome extends StatefulWidget {
  const RaysHome({super.key});
  @override
  State<RaysHome> createState() => _RaysHomeState();
}

class _RaysHomeState extends State<RaysHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  // Per-tab scale controllers for press feedback in nav bar
  late final List<AnimationController> _iconScaleControllers;
  late final List<Animation<double>> _iconScaleAnims;

  static const List<Widget> _screens = [
    DashboardScreen(),
    MobileUsageScreen(),
    InsightsScreen(),
    ScanHistoryScreen(),
    PrivacyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _iconScaleControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        reverseDuration: const Duration(milliseconds: 200),
      ),
    );

    _iconScaleAnims = _iconScaleControllers.map((ctrl) {
      return Tween<double>(begin: 1.0, end: 1.22)
          .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();

    // Animate initial selection
    _iconScaleControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconScaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();

    // Reverse old, forward new
    _iconScaleControllers[_currentIndex].reverse();
    _iconScaleControllers[index].forward();

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _AnimatedNavBar(
        currentIndex: _currentIndex,
        isDark: isDark,
        iconScaleAnims: _iconScaleAnims,
        onTap: _switchTab,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated frosted-glass bottom nav bar with sliding pill indicator
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedNavBar extends StatelessWidget {
  const _AnimatedNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.iconScaleAnims,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final List<Animation<double>> iconScaleAnims;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.backgroundDark.withOpacity(0.72)
                : AppTheme.lightSurface.withOpacity(0.80),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppTheme.glassBorder.withOpacity(0.55)
                    : AppTheme.lightBorder.withOpacity(0.6),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: LayoutBuilder(builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _navItems.length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── Sliding pill indicator ───────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeInOutCubic,
                      left: itemWidth * currentIndex + (itemWidth - 52) / 2,
                      top: 6,
                      child: Container(
                        width: 52,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryCyan.withOpacity(0.18),
                              AppTheme.accentPurple.withOpacity(0.14),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryCyan.withOpacity(0.30),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryCyan.withOpacity(0.12),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Nav items row ─────────────────────────────────────
                    Row(
                      children: List.generate(_navItems.length, (i) {
                        final item   = _navItems[i];
                        final active = i == currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon with scale
                                ScaleTransition(
                                  scale: iconScaleAnims[i],
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                          scale: anim, child: child),
                                    ),
                                    child: Icon(
                                      active ? item.activeIcon : item.icon,
                                      key: ValueKey('${i}_$active'),
                                      color: active
                                          ? AppTheme.primaryCyan
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black45),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Label
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    color: active
                                        ? AppTheme.primaryCyan
                                        : (isDark
                                            ? Colors.white38
                                            : Colors.black45),
                                    fontSize: active ? 10.5 : 9.5,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    letterSpacing: active ? 0.2 : 0,
                                  ),
                                  child: Text(item.label),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
