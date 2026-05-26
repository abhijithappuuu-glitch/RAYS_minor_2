import 'package:flutter/material.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';

/// Personalized advice screen based on stress assessment result
class AdviceScreen extends StatefulWidget {
  final int stressScore;
  final String riskLevel;

  const AdviceScreen({
    super.key,
    required this.stressScore,
    required this.riskLevel,
  });

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.riskLevel) {
      case 'Low':
        return AppTheme.riskLow;
      case 'Medium':
        return AppTheme.riskMedium;
      default:
        return AppTheme.riskHigh;
    }
  }

  List<_AdviceItem> get _quickTips {
    if (widget.stressScore <= 35) {
      return [
        _AdviceItem(Icons.self_improvement, 'Maintain Balance', 'Continue your healthy habits. Regular check-ins help sustain well-being.'),
        _AdviceItem(Icons.nature_people, 'Stay Active', 'Keep up with physical activity — even 20 min walks boost mood.'),
        _AdviceItem(Icons.groups, 'Social Connection', 'Maintain your social connections — they are a buffer against future stress.'),
      ];
    } else if (widget.stressScore <= 65) {
      return [
        _AdviceItem(Icons.air, 'Box Breathing', 'Try 4-4-4-4 breathing: inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat 5 times.'),
        _AdviceItem(Icons.phone_android, 'Digital Detox', 'Take 30-min screen breaks. Notification overload raises cortisol.'),
        _AdviceItem(Icons.nightlight, 'Sleep Hygiene', 'Avoid screens 1 hr before bed. Aim for 7-8 hours consistently.'),
        _AdviceItem(Icons.edit_note, 'Journaling', 'Write 3 things you are grateful for each night — this rewires stress pathways.'),
      ];
    } else {
      return [
        _AdviceItem(Icons.spa, 'Body Scan Meditation', 'Lie down and slowly focus on each body part for 10 minutes to release tension.'),
        _AdviceItem(Icons.directions_walk, 'Walk in Nature', '20 min in green spaces reduces cortisol by 12%. Step outside today.'),
        _AdviceItem(Icons.do_not_disturb_on, 'Limit Stimulation', 'Reduce news, social media, and caffeine. Your nervous system needs rest.'),
        _AdviceItem(Icons.people, 'Talk to Someone', 'Reach out to a friend, family member, or professional. You don\'t have to cope alone.'),
        _AdviceItem(Icons.music_note, 'Calming Sounds', 'Listen to nature sounds or slow-tempo music (60 BPM) to lower heart rate.'),
      ];
    }
  }

  List<_DailyPlan> get _dailyPlan {
    if (widget.stressScore <= 35) {
      return [
        _DailyPlan('Morning', '5 min gratitude meditation', Icons.wb_sunny),
        _DailyPlan('Afternoon', '20 min walk or light exercise', Icons.directions_walk),
        _DailyPlan('Evening', 'Read or do a relaxing hobby', Icons.auto_stories),
      ];
    } else if (widget.stressScore <= 65) {
      return [
        _DailyPlan('Morning', '10 min breathing + light stretch', Icons.wb_sunny),
        _DailyPlan('Mid-Morning', 'Take a break from screens every 50 min', Icons.timer),
        _DailyPlan('Afternoon', '30 min physical activity', Icons.fitness_center),
        _DailyPlan('Evening', 'Journal + avoid screens after 9 PM', Icons.nightlight),
      ];
    } else {
      return [
        _DailyPlan('Morning', '15 min guided meditation', Icons.wb_sunny),
        _DailyPlan('Mid-Morning', '10 min walk + deep breathing', Icons.nature),
        _DailyPlan('Lunch', 'Mindful eating — no phone at meals', Icons.restaurant),
        _DailyPlan('Afternoon', 'Progressive muscle relaxation', Icons.accessibility_new),
        _DailyPlan('Evening', 'Body scan + sleep by 10 PM', Icons.bedtime),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Your Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header card
                    _buildHeaderCard(),
                    const SizedBox(height: 24),

                    // Quick tips
                    const Text(
                      'Personalized Tips',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._quickTips.map(_buildTipCard),

                    const SizedBox(height: 24),

                    // Daily plan
                    const Text(
                      'Suggested Daily Plan',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDailyPlanCard(),

                    const SizedBox(height: 24),

                    // Emergency resources
                    if (widget.stressScore > 65) ...[
                      _buildEmergencyCard(),
                      const SizedBox(height: 24),
                    ],

                    // Done button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final headline = widget.stressScore <= 35
        ? 'You\'re doing great!'
        : widget.stressScore <= 65
            ? 'Let\'s ease the tension'
            : 'We\'re here for you';
    final subtitle = widget.stressScore <= 35
        ? 'Your stress levels are manageable. Here are tips to stay on track.'
        : widget.stressScore <= 65
            ? 'Moderate stress detected. Small daily changes can make a big difference.'
            : 'High stress detected. Please take a moment for yourself — these steps will help.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor.withOpacity(0.25), _accentColor.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            widget.stressScore <= 35
                ? Icons.emoji_emotions
                : widget.stressScore <= 65
                    ? Icons.self_improvement
                    : Icons.favorite,
            color: _accentColor,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: TextStyle(
              color: _accentColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(_AdviceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: _accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPlanCard() {
    return GlassmorphicCard(
      child: Column(
        children: List.generate(_dailyPlan.length, (i) {
          final plan = _dailyPlan[i];
          final isLast = i == _dailyPlan.length - 1;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(plan.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.time, style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(plan.activity, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 17),
                    Container(width: 2, height: 20, color: AppTheme.surfaceLight),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.riskHigh.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.riskHigh.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: AppTheme.riskHigh, size: 24),
              SizedBox(width: 10),
              Text(
                'Need Immediate Help?',
                style: TextStyle(color: AppTheme.riskHigh, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If you feel overwhelmed, please reach out:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildHelpLine('iCall', '9152987821'),
          _buildHelpLine('Vandrevala Foundation', '1860-2662-345'),
          _buildHelpLine('NIMHANS Helpline', '080-46110007'),
        ],
      ),
    );
  }

  Widget _buildHelpLine(String name, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.phone, color: AppTheme.primaryCyan, size: 16),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
          const Spacer(),
          Text(number, style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AdviceItem {
  final IconData icon;
  final String title;
  final String description;
  _AdviceItem(this.icon, this.title, this.description);
}

class _DailyPlan {
  final String time;
  final String activity;
  final IconData icon;
  _DailyPlan(this.time, this.activity, this.icon);
}
