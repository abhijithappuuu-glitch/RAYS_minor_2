import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';

/// A circular ring widget that displays sleep quality as a percentage.
/// Used in the dashboard to visualize sleep data.
class SleepQualityRing extends StatefulWidget {
  final double sleepHours;
  final double targetHours;
  final double size;

  const SleepQualityRing({
    super.key,
    required this.sleepHours,
    this.targetHours = 8.0,
    this.size = 120,
  });

  @override
  State<SleepQualityRing> createState() => _SleepQualityRingState();
}

class _SleepQualityRingState extends State<SleepQualityRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double get _percentage =>
      (widget.sleepHours / widget.targetHours).clamp(0.0, 1.0);

  Color get _color {
    if (_percentage >= 0.875) return AppTheme.riskLow;
    if (_percentage >= 0.625) return AppTheme.riskMedium;
    return AppTheme.riskHigh;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: _percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SleepQualityRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sleepHours != widget.sleepHours) {
      _animation = Tween<double>(begin: _animation.value, end: _percentage)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              color: _color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.sleepHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'sleep',
                    style: TextStyle(
                      fontSize: widget.size * 0.1,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = AppTheme.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
