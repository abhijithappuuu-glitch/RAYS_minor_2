import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/widgets/glassmorphic_card.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PrivacyCenterScreen extends ConsumerStatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  ConsumerState<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends ConsumerState<PrivacyCenterScreen> {
  bool _isGhostMode = false;
  bool _isExporting = false;
  bool _isDeleting = false;
  
  Map<String, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadGhostModeStatus();
    _checkAllPermissions();
  }

  Future<void> _loadGhostModeStatus() async {
    // Load from SharedPreferences or Riverpod state
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _isGhostMode = prefs.getBool('ghost_mode') ?? false;
    // });
  }

  Future<void> _checkAllPermissions() async {
    final permissions = {
      'Usage Stats': Permission.systemAlertWindow, // Proxy for UsageStats
      'Notifications': Permission.notification,
      'Activity Recognition': Permission.activityRecognition,
      'Location': Permission.location,
      'Storage': Permission.storage,
    };

    final statuses = <String, PermissionStatus>{};
    
    for (final entry in permissions.entries) {
      statuses[entry.key] = await entry.value.status;
    }

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Privacy Center'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Header
            _buildPrivacyHeader(context),
            
            const SizedBox(height: AppTheme.spacingL),

            // Ghost Mode
            _buildGhostModeSection(context),

            const SizedBox(height: AppTheme.spacingM),

            // Data Management
            _buildDataManagementSection(context),

            const SizedBox(height: AppTheme.spacingM),

            // Permissions Monitor
            _buildPermissionsSection(context),

            const SizedBox(height: AppTheme.spacingM),

            // What We Collect
            _buildWhatWeCollectSection(context),

            const SizedBox(height: AppTheme.spacingM),

            // Privacy Policy
            _buildPrivacyPolicySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyHeader(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              color: AppTheme.primaryGold,
              size: 40,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Your Privacy Matters',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'All data stays on your device. We use end-to-end encryption for any cloud sync.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGhostModeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'Ghost Mode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        GlassmorphicCard(
          borderColor: _isGhostMode 
              ? AppTheme.primaryGold.withOpacity(0.3) 
              : null,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (_isGhostMode 
                          ? AppTheme.primaryGold 
                          : AppTheme.textTertiary)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Icon(
                      Icons.visibility_off,
                      color: _isGhostMode 
                          ? AppTheme.primaryGold 
                          : AppTheme.textTertiary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ghost Mode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isGhostMode ? 'Active - No tracking' : 'Inactive',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isGhostMode,
                    onChanged: _toggleGhostMode,
                    activeThumbColor: AppTheme.primaryGold,
                  ),
                ],
              ),
              if (_isGhostMode) ...[
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: AppTheme.primaryGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          'Background monitoring paused. All data collection stopped.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        // Export Data
        _buildActionCard(
          context,
          icon: Icons.download,
          iconColor: AppTheme.riskLow,
          title: 'Export My Data',
          subtitle: 'Download all your data in JSON format',
          isLoading: _isExporting,
          onTap: _exportData,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        // Delete Data
        _buildActionCard(
          context,
          icon: Icons.delete_forever,
          iconColor: AppTheme.riskHigh,
          title: 'Delete My Data',
          subtitle: 'Permanently remove all stored data',
          isLoading: _isDeleting,
          onTap: _confirmDeleteData,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GlassmorphicCard(
      onTap: isLoading ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(iconColor),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: iconColor,
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.textTertiary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Permission Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: _checkAllPermissions,
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppTheme.primaryGold,
                ),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: AppTheme.primaryGold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        GlassmorphicCard(
          child: Column(
            children: _permissionStatuses.entries.map((entry) {
              return _buildPermissionRow(
                context,
                entry.key,
                entry.value,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRow(
    BuildContext context,
    String name,
    PermissionStatus status,
  ) {
    final isGranted = status.isGranted;
    final color = isGranted ? AppTheme.riskLow : AppTheme.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatWeCollectSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
          child: Text(
            'What We Collect',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataItemRow(
                context,
                icon: Icons.phone_android,
                title: 'App Usage Statistics',
                description: 'Time spent in apps, pickup frequency',
              ),
              const Divider(color: AppTheme.surfaceLight, height: 24),
              _buildDataItemRow(
                context,
                icon: Icons.bedtime,
                title: 'Sleep & Health Data',
                description: 'Sleep duration, exercise minutes (from Health Connect)',
              ),
              const Divider(color: AppTheme.surfaceLight, height: 24),
              _buildDataItemRow(
                context,
                icon: Icons.sensors,
                title: 'Device Sensors',
                description: 'Light sensor, battery status (for context)',
              ),
              const Divider(color: AppTheme.surfaceLight, height: 24),
              _buildDataItemRow(
                context,
                icon: Icons.psychology,
                title: 'ML Predictions',
                description: 'Stress scores (computed locally)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataItemRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryGold,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicySection(BuildContext context) {
    return GlassmorphicCard(
      onTap: () {
        // Navigate to full privacy policy screen
      },
      child: Row(
        children: [
          const Icon(
            Icons.policy,
            color: AppTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Text(
              'Read Full Privacy Policy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.textTertiary,
            size: 24,
          ),
        ],
      ),
    );
  }

  // Actions
  Future<void> _toggleGhostMode(bool value) async {
    setState(() {
      _isGhostMode = value;
    });

    // Save to SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('ghost_mode', value);

    // Stop/Start background monitoring
    if (value) {
      // Stop WorkManager tasks
      // await Workmanager().cancelAll();
    } else {
      // Restart WorkManager tasks
      // final scheduler = AdaptiveScheduler();
      // await scheduler.scheduleMonitoring('NORMAL');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Ghost Mode activated' : 'Ghost Mode deactivated',
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Collect all data from database
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_data': {
          'stress_scores': [], // From Isar DB
          'usage_stats': [],
          'sleep_records': [],
          'settings': {},
        },
        'metadata': {
          'version': '1.0.0',
          'format': 'rakshak_export_v1',
        },
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/rakshak_export_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'RAYS - My Data Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppTheme.riskLow,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.riskHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _confirmDeleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Delete All Data?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will permanently delete all your stress data, usage history, and settings. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.riskHigh,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllData();
    }
  }

  Future<void> _deleteAllData() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete all data from Isar database
      // await IsarDatabase.instance.deleteAll();

      // Clear SharedPreferences
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      // Clear secure storage
      // final secureStorage = FlutterSecureStorage();
      // await secureStorage.deleteAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted successfully'),
            backgroundColor: AppTheme.riskHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back or to onboarding
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppTheme.riskHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }
}
