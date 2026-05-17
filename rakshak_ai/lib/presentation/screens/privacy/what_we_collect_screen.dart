import 'package:flutter/material.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';

class WhatWeCollectScreen extends StatelessWidget {
  const WhatWeCollectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('What We Collect'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy commitment
            GlassmorphicCard(
              backgroundColor: AppTheme.riskLow.withOpacity(0.1),
              borderColor: AppTheme.riskLow.withOpacity(0.3),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: AppTheme.riskLow, size: 32),
                  SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy First',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All data is processed locally on your device. We never sell your data.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            Text(
              'Data We Collect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),

            _buildDataCategory(
              context,
              icon: Icons.phone_android,
              title: 'App Usage Data',
              items: [
                'Screen time per app category',
                'App open frequency',
                'Late night usage (12 AM - 4 AM)',
                'Continuous social media sessions',
              ],
              purpose: 'Identify digital behavior patterns linked to stress',
            ),

            _buildDataCategory(
              context,
              icon: Icons.bedtime,
              title: 'Sleep Data (via Health Connect)',
              items: [
                'Sleep duration',
                'Sleep start/end time',
                'Sleep consistency over 7 days',
              ],
              purpose: 'Correlate sleep quality with stress levels',
            ),

            _buildDataCategory(
              context,
              icon: Icons.fitness_center,
              title: 'Exercise Data (via Health Connect)',
              items: [
                'Daily exercise minutes',
                'Step count',
                'Activity type',
              ],
              purpose: 'Factor physical activity into wellness score',
            ),

            _buildDataCategory(
              context,
              icon: Icons.favorite,
              title: 'Heart Rate (via Health Connect)',
              items: [
                'Resting heart rate',
              ],
              purpose: 'Physiological stress indicator',
            ),

            _buildDataCategory(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Context Signals',
              items: [
                'Ambient light level',
                'Charging status',
                'Device pickup frequency',
              ],
              purpose: 'Detect nighttime phone usage in dark rooms',
            ),

            const SizedBox(height: AppTheme.spacingL),

            Text(
              'Data We DON\'T Collect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),

            GlassmorphicCard(
              child: Column(
                children: [
                  _buildNoCollectItem(Icons.message, 'Message contents'),
                  const Divider(color: AppTheme.glassBorder),
                  _buildNoCollectItem(Icons.call, 'Call logs or contacts'),
                  const Divider(color: AppTheme.glassBorder),
                  _buildNoCollectItem(Icons.location_on, 'Location data'),
                  const Divider(color: AppTheme.glassBorder),
                  _buildNoCollectItem(Icons.photo, 'Photos or files'),
                  const Divider(color: AppTheme.glassBorder),
                  _buildNoCollectItem(Icons.fingerprint, 'Biometric data'),
                  const Divider(color: AppTheme.glassBorder),
                  _buildNoCollectItem(Icons.person, 'Personal identifiers'),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            Text(
              'Data Storage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),

            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStorageItem(
                    Icons.smartphone,
                    'Local Only',
                    'All data stored on your device',
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildStorageItem(
                    Icons.lock,
                    'AES-256 Encrypted',
                    'Military-grade encryption at rest',
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildStorageItem(
                    Icons.delete_forever,
                    'User Controlled',
                    'Delete all data anytime from Privacy Center',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            Center(
              child: Text(
                'Compliant with India DPDP Act 2023',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCategory(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> items,
    required String purpose,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: GlassmorphicCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryGold, size: 24),
                const SizedBox(width: AppTheme.spacingS),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Flexible(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      purpose,
                      style: const TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCollectItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.riskHigh.withOpacity(0.7), size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppTheme.riskHigh,
            ),
          ),
          const Spacer(),
          const Icon(Icons.close, color: AppTheme.riskHigh, size: 18),
        ],
      ),
    );
  }

  Widget _buildStorageItem(IconData icon, String title, String subtitle) {
    return Row(
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

