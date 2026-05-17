import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/features/native_integrations/platform_channels.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';

/// Widget showing current permission status
class PermissionStatusMonitor extends ConsumerStatefulWidget {
  const PermissionStatusMonitor({super.key});

  @override
  ConsumerState<PermissionStatusMonitor> createState() =>
      _PermissionStatusMonitorState();
}

class _PermissionStatusMonitorState
    extends ConsumerState<PermissionStatusMonitor> {
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final usageStats = await PlatformChannels.hasUsagePermission();
    final notifications = await Permission.notification.isGranted;
    final activityRecognition = await Permission.activityRecognition.isGranted;
    final sensors = await Permission.sensors.isGranted;

    setState(() {
      _permissions = {
        'Usage Stats': usageStats,
        'Notifications': notifications,
        'Activity Recognition': activityRecognition,
        'Sensors': sensors,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassmorphicCard(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    final allGranted = _permissions.values.every((v) => v);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allGranted ? Icons.check_circle : Icons.warning_amber,
                color: allGranted ? AppTheme.riskLow : AppTheme.riskMedium,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Permission Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: AppTheme.textSecondary,
                onPressed: () {
                  setState(() => _isLoading = true);
                  _checkAllPermissions();
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          ..._permissions.entries.map((entry) => _buildPermissionRow(
                entry.key,
                entry.value,
              )),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: granted ? AppTheme.riskLow : AppTheme.riskHigh,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Text(
            granted ? 'Granted' : 'Denied',
            style: TextStyle(
              color: granted ? AppTheme.riskLow : AppTheme.riskHigh,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

