import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:rakshak_ai/presentation/providers/scan_provider.dart';

/// Google Fit integration screen showing fitness data
class FitnessScreen extends ConsumerStatefulWidget {
  final FitnessSnapshot? fitnessData;
  const FitnessScreen({super.key, this.fitnessData});

  @override
  ConsumerState<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends ConsumerState<FitnessScreen> {
  late bool _isConnected;
  late _FitnessData _fitnessData;

  @override
  void initState() {
    super.initState();
    final snap = widget.fitnessData;
    if (snap != null && snap.steps > 0) {
      _isConnected = true;
      _fitnessData = _FitnessData(
        steps: snap.steps,
        stepsGoal: 10000,
        heartRate: snap.heartRate,
        sleepHours: snap.sleepHours,
        sleepGoal: 8.0,
        caloriesBurned: snap.caloriesBurned,
        caloriesGoal: 2200,
        exerciseMinutes: snap.exerciseMinutes,
        exerciseGoal: 30,
        waterGlasses: snap.waterGlasses,
        waterGoal: 8,
      );
    } else {
      _isConnected = false;
      _fitnessData = _FitnessData(
        steps: 0,
        stepsGoal: 10000,
        heartRate: 0,
        sleepHours: 0,
        sleepGoal: 8.0,
        caloriesBurned: 0,
        caloriesGoal: 2200,
        exerciseMinutes: 0,
        exerciseGoal: 30,
        waterGlasses: 0,
        waterGoal: 8,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
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
                'Fitness & Health',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Google Fit connection
                  if (!_isConnected)
                    _buildConnectCard()
                  else ...[
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildStepsCard(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildHeartRateCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSleepCard()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildCaloriesCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildExerciseCard()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildWaterCard(),
                    const SizedBox(height: 20),
                    _buildStressImpactCard(),
                    const SizedBox(height: 32),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connect Google Fit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your fitness tracker to get comprehensive health insights and better stress analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Load from scan provider if available
                final scanState = ref.read(scanProvider);
                if (scanState.hasScanned && scanState.lastScan != null) {
                  final snap = scanState.lastScan!.fitness;
                  setState(() {
                    _isConnected = true;
                    _fitnessData = _FitnessData(
                      steps: snap.steps,
                      stepsGoal: 10000,
                      heartRate: snap.heartRate,
                      sleepHours: snap.sleepHours,
                      sleepGoal: 8.0,
                      caloriesBurned: snap.caloriesBurned,
                      caloriesGoal: 2200,
                      exerciseMinutes: snap.exerciseMinutes,
                      exerciseGoal: 30,
                      waterGlasses: snap.waterGlasses,
                      waterGoal: 8,
                    );
                  });
                } else {
                  setState(() => _isConnected = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link),
                  SizedBox(width: 8),
                  Text('Connect Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              final scanState = ref.read(scanProvider);
              if (scanState.hasScanned && scanState.lastScan != null) {
                final snap = scanState.lastScan!.fitness;
                setState(() {
                  _isConnected = true;
                  _fitnessData = _FitnessData(
                    steps: snap.steps,
                    stepsGoal: 10000,
                    heartRate: snap.heartRate,
                    sleepHours: snap.sleepHours,
                    sleepGoal: 8.0,
                    caloriesBurned: snap.caloriesBurned,
                    caloriesGoal: 2200,
                    exerciseMinutes: snap.exerciseMinutes,
                    exerciseGoal: 30,
                    waterGlasses: snap.waterGlasses,
                    waterGoal: 8,
                  );
                });
              } else {
                setState(() => _isConnected = true);
              }
            },
            child: const Text(
              'Use scanned data',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildMiniStat(Icons.favorite, '${_fitnessData.heartRate}', 'BPM', AppTheme.riskHigh),
        const SizedBox(width: 8),
        _buildMiniStat(Icons.directions_walk, '${_fitnessData.steps}', 'Steps', AppTheme.primaryCyan),
        const SizedBox(width: 8),
        _buildMiniStat(Icons.local_fire_department, '${_fitnessData.caloriesBurned}', 'kcal', AppTheme.riskMedium),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    final pct = (_fitnessData.steps / _fitnessData.stepsGoal).clamp(0.0, 1.0);
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk, color: AppTheme.primaryCyan, size: 24),
              const SizedBox(width: 10),
              const Text('Steps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(
                '${_fitnessData.steps} / ${_fitnessData.stepsGoal}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryCyan),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).round()}% of daily goal',
            style: TextStyle(
              color: pct >= 1.0 ? AppTheme.riskLow : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: AppTheme.riskHigh, size: 22),
          const SizedBox(height: 10),
          const Text('Heart Rate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fitnessData.heartRate}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('bpm', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _fitnessData.heartRate < 60
                ? 'Low'
                : _fitnessData.heartRate <= 100
                    ? 'Normal'
                    : 'Elevated',
            style: TextStyle(
              color: _fitnessData.heartRate <= 100 ? AppTheme.riskLow : AppTheme.riskHigh,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime, color: AppTheme.accentPurple, size: 22),
          const SizedBox(height: 10),
          const Text('Sleep', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fitnessData.sleepHours}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('hrs', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _fitnessData.sleepHours >= 7
                ? 'Good'
                : _fitnessData.sleepHours >= 5
                    ? 'Fair'
                    : 'Poor',
            style: TextStyle(
              color: _fitnessData.sleepHours >= 7
                  ? AppTheme.riskLow
                  : _fitnessData.sleepHours >= 5
                      ? AppTheme.riskMedium
                      : AppTheme.riskHigh,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_fire_department, color: AppTheme.riskMedium, size: 22),
          const SizedBox(height: 10),
          const Text('Calories', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fitnessData.caloriesBurned}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('kcal', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.riskLow, size: 22),
          const SizedBox(height: 10),
          const Text('Exercise', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fitnessData.exerciseMinutes}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('min', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_fitnessData.exerciseMinutes}/${_fitnessData.exerciseGoal} min goal',
            style: TextStyle(
              color: _fitnessData.exerciseMinutes >= _fitnessData.exerciseGoal
                  ? AppTheme.riskLow
                  : AppTheme.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppTheme.primaryCyan, size: 22),
              const SizedBox(width: 10),
              const Text('Water Intake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text(
                '${_fitnessData.waterGlasses}/${_fitnessData.waterGoal} glasses',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_fitnessData.waterGoal, (i) {
              final filled = i < _fitnessData.waterGlasses;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: filled
                          ? AppTheme.primaryCyan.withOpacity(0.3)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: filled
                          ? Border.all(color: AppTheme.primaryCyan.withOpacity(0.5))
                          : null,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 16,
                      color: filled ? AppTheme.primaryCyan : AppTheme.textTertiary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStressImpactCard() {
    final sleepOk = _fitnessData.sleepHours >= 7;
    final exerciseOk = _fitnessData.exerciseMinutes >= _fitnessData.exerciseGoal;
    final stepsOk = _fitnessData.steps >= _fitnessData.stepsGoal * 0.7;

    return GlassmorphicCard(
      borderColor: AppTheme.accentPurple.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.accentPurple, size: 24),
              SizedBox(width: 10),
              Text(
                'Fitness & Stress Link',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckRow('Sleep Quality', sleepOk ? 'Adequate rest reduces cortisol' : 'Poor sleep increases stress hormones', sleepOk),
          const SizedBox(height: 10),
          _buildCheckRow('Physical Activity', exerciseOk ? 'Exercise goal met - endorphins released' : 'More activity can lower stress', exerciseOk),
          const SizedBox(height: 10),
          _buildCheckRow('Daily Movement', stepsOk ? 'Active lifestyle helps manage stress' : 'Try to move more throughout the day', stepsOk),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String title, String desc, bool good) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          good ? Icons.check_circle : Icons.radio_button_unchecked,
          color: good ? AppTheme.riskLow : AppTheme.textTertiary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FitnessData {
  final int steps, stepsGoal, heartRate, caloriesBurned, caloriesGoal, exerciseMinutes, exerciseGoal, waterGlasses, waterGoal;
  final double sleepHours, sleepGoal;

  _FitnessData({
    required this.steps, required this.stepsGoal, required this.heartRate,
    required this.sleepHours, required this.sleepGoal,
    required this.caloriesBurned, required this.caloriesGoal,
    required this.exerciseMinutes, required this.exerciseGoal,
    required this.waterGlasses, required this.waterGoal,
  });
}
