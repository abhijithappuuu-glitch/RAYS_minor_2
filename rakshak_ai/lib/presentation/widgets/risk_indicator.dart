import 'package:flutter/material.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';

class RiskIndicator extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final String severity;

  const RiskIndicator({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.severity = 'medium',
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = isActive
        ? AppTheme.getStressColor(severity)
        : AppTheme.textTertiary;

    return GlassmorphicCard(
      borderColor: isActive ? indicatorColor.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              color: indicatorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isActive
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? indicatorColor : AppTheme.surfaceLight,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: indicatorColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
