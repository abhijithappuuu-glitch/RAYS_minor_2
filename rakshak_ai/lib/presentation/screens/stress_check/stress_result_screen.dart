import 'package:flutter/material.dart';
import 'dart:math';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/screens/advice/advice_screen.dart';

class StressResultScreen extends StatefulWidget {
  final int score;
  const StressResultScreen({super.key, required this.score});

  @override
  State<StressResultScreen> createState() => _StressResultScreenState();
}

class _StressResultScreenState extends State<StressResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnim = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _riskLevel {
    if (widget.score >= 70) return 'high';
    if (widget.score >= 40) return 'medium';
    return 'low';
  }

  String get _title {
    switch (_riskLevel) {
      case 'high':
        return 'High Stress Detected';
      case 'medium':
        return 'Moderate Stress';
      default:
        return 'You\'re Doing Great!';
    }
  }

  String get _subtitle {
    switch (_riskLevel) {
      case 'high':
        return 'Your stress levels are elevated. Let\'s work on bringing them down with some personalized suggestions.';
      case 'medium':
        return 'You\'re managing okay, but there\'s room for improvement. Small changes can make a big difference.';
      default:
        return 'Your stress levels are low. Keep up the amazing work and maintain your healthy habits!';
    }
  }

  IconData get _icon {
    switch (_riskLevel) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.celebration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStressColor(_riskLevel);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Animated circular score
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: _scoreAnim.value / 100,
                        color: color,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_scoreAnim.value.round()}',
                              style: TextStyle(
                                color: color,
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stress Score',
                              style: TextStyle(
                                color: color.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Result info
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Icon(_icon, size: 48, color: color),
                        const SizedBox(height: 16),
                        Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => AdviceScreen(
                                    stressScore: widget.score,
                                    riskLevel: _riskLevel,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb_outline),
                                SizedBox(width: 8),
                                Text(
                                  'Get Personalized Advice',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withOpacity(0.4), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );

    // Glow dot at end
    if (progress > 0) {
      final angle = -pi / 2 + 2 * pi * progress;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(
        dotCenter,
        8,
        Paint()..color = color,
      );
      canvas.drawCircle(
        dotCenter,
        16,
        Paint()..color = color.withOpacity(0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress;
}
