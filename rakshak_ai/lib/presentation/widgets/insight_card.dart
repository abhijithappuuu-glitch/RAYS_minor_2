import 'package:flutter/material.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String type; // 'positive', 'warning', 'info'

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.type = 'info',
  });

  Color _getColor() {
    switch (type) {
      case 'positive':
        return AppTheme.riskLow;
      case 'warning':
        return AppTheme.riskMedium;
      case 'danger':
        return AppTheme.riskHigh;
      default:
        return AppTheme.primaryGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GlassmorphicCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
}
