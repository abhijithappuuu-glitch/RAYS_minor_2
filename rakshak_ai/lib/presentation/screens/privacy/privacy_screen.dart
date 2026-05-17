import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/core/services/data_export_service.dart';
import 'package:rakshak_ai/core/theme/app_theme.dart';
import 'package:rakshak_ai/presentation/providers/settings_provider.dart';
import 'package:rakshak_ai/presentation/widgets/permission_status_monitor.dart';
import 'package:rakshak_ai/presentation/screens/privacy/what_we_collect_screen.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            elevation: 0,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: const Text(
                'Privacy & Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Privacy Banner ────────────────────────────────
                _buildBannerCard(),

                const SizedBox(height: 28),

                // ── Appearance ──────────────────────────────────
                _SectionHeader(label: 'Appearance'),
                const SizedBox(height: 10),
                _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  activeIcon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme throughout the app',
                  value: settings.darkModeEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).toggleDarkMode(v),
                ),

                const SizedBox(height: 28),

                // ── Privacy Controls ────────────────────────────
                _SectionHeader(label: 'Privacy Controls'),
                const SizedBox(height: 10),
                _ToggleTile(
                  icon: Icons.visibility_off_outlined,
                  activeIcon: Icons.visibility_off,
                  title: 'Ghost Mode',
                  subtitle: 'Pause all monitoring and data collection',
                  value: settings.ghostModeEnabled,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).toggleGhostMode(v),
                  activeColor: AppTheme.riskHigh,
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Smart stress alerts and interventions',
                  value: settings.notificationsEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .toggleNotifications(v),
                ),
                const SizedBox(height: 8),
                _ToggleTile(
                  icon: Icons.fingerprint,
                  activeIcon: Icons.fingerprint,
                  title: 'Biometric Lock',
                  subtitle: 'Require fingerprint to open RAYS',
                  value: settings.biometricLockEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .toggleBiometricLock(v),
                ),

                const SizedBox(height: 28),

                // ── Permission Status ────────────────────────────
                _SectionHeader(label: 'Permission Status'),
                const SizedBox(height: 10),
                const PermissionStatusMonitor(),

                const SizedBox(height: 28),

                // ── Data Management ─────────────────────────────
                _SectionHeader(label: 'Data Management'),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.download_outlined,
                  iconColor: AppTheme.primaryCyan,
                  title: 'Export My Data',
                  subtitle: 'Download all your data as JSON',
                  trailingIcon: Icons.chevron_right,
                  trailingColor: Colors.white38,
                  onTap: () => _exportData(context),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.delete_outline,
                  iconColor: AppTheme.riskHigh,
                  title: 'Delete All Data',
                  subtitle: 'Permanently erase all collected data',
                  trailingIcon: Icons.chevron_right,
                  trailingColor: AppTheme.riskHigh,
                  onTap: () => _showDeleteConfirmation(context),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.info_outline,
                  iconColor: AppTheme.textSecondary,
                  title: 'What We Collect',
                  subtitle: 'See exactly what data RAYS uses',
                  trailingIcon: Icons.chevron_right,
                  trailingColor: Colors.white38,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatWeCollectScreen()),
                  ),
                ),

                const SizedBox(height: 28),

                // ── App Info ────────────────────────────────────
                _SectionHeader(label: 'About'),
                const SizedBox(height: 10),
                _buildInfoCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryCyan.withOpacity(0.15),
            AppTheme.accentPurple.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.primaryCyan, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data stays on your device',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All processing happens locally. Nothing is shared without your consent.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_outlined,
                  color: AppTheme.primaryCyan, size: 22),
              SizedBox(width: 10),
              Text(
                'RAYS — Stress Intelligence',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.glassBorder),
          const SizedBox(height: 8),
          _infoRow('Version', '1.0.0'),
          _infoRow('Build', 'Release Ready'),
          _infoRow('Data Policy', 'On-device only'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    final exportService = getIt<DataExportService>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting data...')),
    );
    try {
      await exportService.shareExportedData();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F36),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
        title: const Text('Delete All Data?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This cannot be undone. All stress data, scan history, and insights will be permanently erased.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.primaryCyan)),
          ),
          TextButton(
            onPressed: () async {
              final exportService = getIt<DataExportService>();
              await exportService.deleteAllData();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Section Header ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.primaryCyan,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Toggle Tile ─────────────────────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleTile({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor = AppTheme.primaryCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (value ? activeColor : Colors.white24).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            value ? activeIcon : icon,
            color: value ? activeColor : Colors.white38,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: Colors.white12,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }
}

// ── Action Tile ─────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final Color trailingColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Icon(trailingIcon, color: trailingColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
