import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;

  String _instruction = 'Tap to Start';
  int _currentPhase = 0; // 0: idle, 1: inhale, 2: hold, 3: exhale, 4: hold
  int _cycleCount = 0;
  final int _totalCycles = 4;
  Timer? _phaseTimer;
  bool _isRunning = false;

  static const _phaseDurations = [0, 4, 4, 6, 2]; // seconds for each phase
  static const _phaseInstructions = [
    'Tap to Start',
    'Breathe In',
    'Hold',
    'Breathe Out',
    'Hold'
  ];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _cycleCount = 0;
    });
    _nextPhase();
  }

  void _nextPhase() {
    setState(() {
      _currentPhase = (_currentPhase % 4) + 1;
      _instruction = _phaseInstructions[_currentPhase];
    });

    // Haptic feedback on phase change
    HapticFeedback.mediumImpact();

    // Control animation based on phase
    if (_currentPhase == 1) {
      // Inhale - expand
      _breathController.duration = Duration(seconds: _phaseDurations[1]);
      _breathController.forward(from: 0);
    } else if (_currentPhase == 3) {
      // Exhale - contract
      _breathController.duration = Duration(seconds: _phaseDurations[3]);
      _breathController.reverse(from: 1);
    }

    // Schedule next phase
    _phaseTimer = Timer(
      Duration(seconds: _phaseDurations[_currentPhase]),
      () {
        if (_currentPhase == 4) {
          _cycleCount++;
          if (_cycleCount >= _totalCycles) {
            _completeExercise();
            return;
          }
        }
        _nextPhase();
      },
    );
  }

  void _completeExercise() {
    setState(() {
      _isRunning = false;
      _currentPhase = 0;
      _instruction = 'Well Done! 🎉';
    });
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Breathing Exercise',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Breathing Circle
            GestureDetector(
              onTap: _isRunning ? null : _startExercise,
              child: AnimatedBuilder(
                animation: Listenable.merge([_breathAnimation, _pulseAnimation]),
                builder: (context, child) {
                  final scale = _isRunning
                      ? _breathAnimation.value
                      : _pulseAnimation.value * 0.6;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getPhaseColor().withOpacity(0.8),
                            _getPhaseColor().withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getPhaseColor().withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _isRunning && _currentPhase > 0
                                  ? '${_phaseDurations[_currentPhase]}'
                                  : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 60),
            // Instruction Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _instruction,
                key: ValueKey(_instruction),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Progress Indicator
            if (_isRunning)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalCycles, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _cycleCount
                          ? AppTheme.riskLow
                          : Colors.white24,
                    ),
                  );
                }),
              ),
            const Spacer(),
            // Tips
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _isRunning
                    ? 'Follow the circle and relax'
                    : 'This 4-7-8 technique helps reduce anxiety and promote calm',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case 1:
        return const Color(0xFF4CAF50); // Inhale - Green
      case 2:
        return const Color(0xFFFFD700); // Hold - Gold
      case 3:
        return const Color(0xFF2196F3); // Exhale - Blue
      case 4:
        return const Color(0xFFFFD700); // Hold - Gold
      default:
        return const Color(0xFFFFD700); // Idle - Gold
    }
  }
}

