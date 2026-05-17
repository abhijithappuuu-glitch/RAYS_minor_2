import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/screens/stress_check/stress_result_screen.dart';
import 'package:rakshak_ai/presentation/widgets/app_page_route.dart';

/// PSS-4 based quick stress questionnaire with modern UI
class StressQuestionnaireScreen extends ConsumerStatefulWidget {
  /// When true, the screen pops with the score instead of navigating to results
  final bool returnScore;
  const StressQuestionnaireScreen({super.key, this.returnScore = false});

  @override
  ConsumerState<StressQuestionnaireScreen> createState() =>
      _StressQuestionnaireScreenState();
}

class _StressQuestionnaireScreenState
    extends ConsumerState<StressQuestionnaireScreen>
    with SingleTickerProviderStateMixin {
  int _currentQ = 0;
  final Map<int, int> _answers = {};
  late AnimationController _animController;

  static const _questions = [
    {
      'q': 'How often have you felt nervous or stressed today?',
      'icon': Icons.psychology_outlined,
      'options': ['Never', 'Almost Never', 'Sometimes', 'Fairly Often', 'Very Often'],
    },
    {
      'q': 'How confident do you feel about handling your personal problems?',
      'icon': Icons.shield_outlined,
      'options': ['Very Confident', 'Confident', 'Neutral', 'Not Very', 'Not At All'],
      'reverse': true,
    },
    {
      'q': 'How often have you felt things were going your way today?',
      'icon': Icons.trending_up_outlined,
      'options': ['Very Often', 'Fairly Often', 'Sometimes', 'Almost Never', 'Never'],
      'reverse': true,
    },
    {
      'q': 'How often have you felt difficulties piling up so high you could not overcome them?',
      'icon': Icons.layers_outlined,
      'options': ['Never', 'Almost Never', 'Sometimes', 'Fairly Often', 'Very Often'],
    },
    {
      'q': 'How well did you sleep last night?',
      'icon': Icons.bedtime_outlined,
      'options': ['Excellent', 'Good', 'Fair', 'Poor', 'Very Poor'],
      'reverse': true,
    },
    {
      'q': 'How would you rate your energy level right now?',
      'icon': Icons.bolt_outlined,
      'options': ['Very High', 'High', 'Moderate', 'Low', 'Very Low'],
      'reverse': true,
    },
    {
      'q': 'Have you been able to focus on tasks today?',
      'icon': Icons.center_focus_strong_outlined,
      'options': ['Very Easily', 'Easily', 'Somewhat', 'With Difficulty', 'Not At All'],
      'reverse': true,
    },
    {
      'q': 'How connected do you feel with people around you?',
      'icon': Icons.people_outline,
      'options': ['Very Connected', 'Connected', 'Neutral', 'Isolated', 'Very Isolated'],
      'reverse': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _answers[_currentQ] = index;
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      if (_currentQ < _questions.length - 1) {
        _animController.reset();
        setState(() => _currentQ++);
        _animController.forward();
      } else {
        _showResults();
      }
    });
  }

  int _calculateScore() {
    int total = 0;
    for (int i = 0; i < _questions.length; i++) {
      final isReverse = _questions[i]['reverse'] == true;
      final answer = _answers[i] ?? 2;
      total += isReverse ? (4 - answer) : answer;
    }
    // Normalize to 0-100
    return ((total / (_questions.length * 4)) * 100).round().clamp(0, 100);
  }

  void _showResults() {
    final score = _calculateScore();
    if (widget.returnScore) {
      Navigator.of(context).pop(score);
    } else {
      Navigator.of(context).push(
        AppPageRoute(
          builder: (_) => StressResultScreen(score: score),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQ];
    final progress = (_currentQ + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_currentQ > 0) {
                        _animController.reset();
                        setState(() => _currentQ--);
                        _animController.forward();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Question ${_currentQ + 1} of ${_questions.length}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryCyan),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.returnScore)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),

              const Spacer(flex: 1),

              // Question + Options (slide transition on each new question)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  // ENTERING child slides in from right; EXITING slides out to left
                  final isEntering = animation.status == AnimationStatus.forward ||
                      animation.value > 0.5;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(isEntering ? 0.12 : -0.12, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentQ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryCyan.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          q['icon'] as IconData,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        q['q'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ...List.generate(
                        (q['options'] as List).length,
                        (i) => _buildOption(i, (q['options'] as List)[i] as String),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int index, String text) {
    final isSelected = _answers[_currentQ] == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAnswer(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppTheme.glassBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : AppTheme.surfaceLight,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
