import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/features/native_integrations/platform_channels.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/providers/user_profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  late final PageController _pageController;

  // Per-page entry animation controller (reused on each page change)
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  bool _usagePermissionGranted = false;
  bool _notificationPermissionGranted = false;
  final bool _healthPermissionGranted = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
    _checkPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _entryCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    _entryCtrl.forward(from: 0);
  }

  Future<void> _checkPermissions() async {
    final usageGranted = await PlatformChannels.hasUsagePermission();
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _usagePermissionGranted = usageGranted;
      _notificationPermissionGranted = notificationStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildWelcomePage(),
                      _buildProfilePage(),
                      _buildUsagePermissionPage(),
                      _buildNotificationPermissionPage(),
                      _buildHealthPermissionPage(),
                      _buildReadyPage(),
                    ],
                  ),
                ),
              ),
            ),
            _buildPageIndicators(),
            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryCyan, AppTheme.accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            'Welcome to RAYS',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Your intelligent companion for mental wellness. We help you understand your digital habits and their impact on your stress levels.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          _buildNextButton('Get Started'),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 40, color: AppTheme.accentPurple),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Tell Us About You',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'This helps us personalize your experience',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.person, color: AppTheme.primaryCyan),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: const BorderSide(color: AppTheme.primaryCyan),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Your Age',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.cake, color: AppTheme.primaryCyan),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: const BorderSide(color: AppTheme.primaryCyan),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your age';
                final age = int.tryParse(v.trim());
                if (age == null || age < 5 || age > 120) return 'Enter a valid age (5-120)';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text.trim();
                    final age = int.parse(_ageController.text.trim());
                    ref.read(userProfileProvider.notifier).saveProfile(name, age);
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagePermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_android,
            size: 80,
            color: _usagePermissionGranted
                ? AppTheme.riskLow
                : AppTheme.primaryGold,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Usage Statistics Access',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          GlassmorphicCard(
            child: Column(
              children: [
                _buildPermissionItem(
                  Icons.access_time,
                  'Screen Time Tracking',
                  'Understand your daily phone usage',
                ),
                const Divider(color: AppTheme.glassBorder),
                _buildPermissionItem(
                  Icons.apps,
                  'App Usage Analysis',
                  'Identify patterns in social media use',
                ),
                const Divider(color: AppTheme.glassBorder),
                _buildPermissionItem(
                  Icons.nightlight,
                  'Late Night Detection',
                  'Track usage during sleeping hours',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_usagePermissionGranted)
            _buildPermissionGrantedChip()
          else
            ElevatedButton.icon(
              onPressed: () async {
                await PlatformChannels.requestUsagePermission();
                await _checkPermissions();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingM),
          _buildNextButton('Continue'),
        ],
      ),
    );
  }

  Widget _buildNotificationPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 80,
            color: _notificationPermissionGranted
                ? AppTheme.riskLow
                : AppTheme.primaryGold,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Smart Notifications',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Receive gentle, context-aware interventions when you need them most.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          GlassmorphicCard(
            child: Column(
              children: [
                _buildPermissionItem(
                  Icons.psychology,
                  'Stress Alerts',
                  'Get notified when stress levels rise',
                ),
                const Divider(color: AppTheme.glassBorder),
                _buildPermissionItem(
                  Icons.self_improvement,
                  'Wellness Reminders',
                  'Breathing exercises and break suggestions',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_notificationPermissionGranted)
            _buildPermissionGrantedChip()
          else
            ElevatedButton.icon(
              onPressed: () async {
                await Permission.notification.request();
                await _checkPermissions();
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Enable Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingM),
          _buildNextButton('Continue'),
        ],
      ),
    );
  }

  Widget _buildHealthPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 80,
            color: _healthPermissionGranted
                ? AppTheme.riskLow
                : AppTheme.primaryGold,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Health Data Integration',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Connect with Health Connect for comprehensive wellness insights.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          GlassmorphicCard(
            child: Column(
              children: [
                _buildPermissionItem(
                  Icons.bedtime,
                  'Sleep Tracking',
                  'Analyze your sleep patterns',
                ),
                const Divider(color: AppTheme.glassBorder),
                _buildPermissionItem(
                  Icons.directions_run,
                  'Exercise Data',
                  'Factor in physical activity',
                ),
                const Divider(color: AppTheme.glassBorder),
                _buildPermissionItem(
                  Icons.monitor_heart,
                  'Heart Rate',
                  'Monitor resting heart rate trends',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Optional - Skip if Health Connect is not available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildNextButton('Continue'),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: AppTheme.riskLow,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'You\'re All Set!',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'RAYS will now silently monitor your digital wellness and provide personalized insights.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          GlassmorphicCard(
            child: Column(
              children: [
                _buildFeatureItem(Icons.lock, 'Privacy First',
                    'All data processed on-device'),
                _buildFeatureItem(Icons.battery_charging_full,
                    'Battery Optimized', 'Minimal impact on battery'),
                _buildFeatureItem(Icons.auto_awesome, 'AI Powered',
                    'Smart stress predictions'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
              ),
              child: const Text(
                'Start Using RAYS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 24),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.riskLow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.riskLow, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGrantedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.riskLow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: AppTheme.riskLow, size: 18),
          SizedBox(width: 8),
          Text(
            'Permission Granted',
            style: TextStyle(color: AppTheme.riskLow),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String text) {
    return TextButton(
      onPressed: () {
        if (_currentPage < 5) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          width: isActive ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppTheme.primaryCyan, AppTheme.accentPurple],
                  )
                : null,
            color: isActive ? null : AppTheme.surfaceLight.withOpacity(0.45),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withOpacity(0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

