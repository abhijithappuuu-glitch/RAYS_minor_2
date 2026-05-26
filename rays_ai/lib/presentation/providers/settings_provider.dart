import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings state
class AppSettings {
  final bool ghostModeEnabled;
  final bool notificationsEnabled;
  final bool biometricLockEnabled;
  final String monitoringFrequency; // 'normal', 'high_risk', 'ghost'
  final bool darkModeEnabled;

  const AppSettings({
    this.ghostModeEnabled = false,
    this.notificationsEnabled = true,
    this.biometricLockEnabled = false,
    this.monitoringFrequency = 'normal',
    this.darkModeEnabled = true,
  });

  AppSettings copyWith({
    bool? ghostModeEnabled,
    bool? notificationsEnabled,
    bool? biometricLockEnabled,
    String? monitoringFrequency,
    bool? darkModeEnabled,
  }) {
    return AppSettings(
      ghostModeEnabled: ghostModeEnabled ?? this.ghostModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      monitoringFrequency: monitoringFrequency ?? this.monitoringFrequency,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kDarkMode        = 'pref_dark_mode';
  static const _kGhostMode       = 'pref_ghost_mode';
  static const _kNotifications   = 'pref_notifications';
  static const _kBiometric       = 'pref_biometric';
  static const _kMonitoringFreq  = 'pref_monitoring_freq';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      darkModeEnabled:      prefs.getBool(_kDarkMode)       ?? true,
      ghostModeEnabled:     prefs.getBool(_kGhostMode)      ?? false,
      notificationsEnabled: prefs.getBool(_kNotifications)  ?? true,
      biometricLockEnabled: prefs.getBool(_kBiometric)      ?? false,
      monitoringFrequency:  prefs.getString(_kMonitoringFreq) ?? 'normal',
    );
  }

  void toggleGhostMode(bool value) {
    state = state.copyWith(
      ghostModeEnabled: value,
      monitoringFrequency: value ? 'ghost' : 'normal',
    );
    _save(_kGhostMode, value);
    _saveString(_kMonitoringFreq, state.monitoringFrequency);
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    _save(_kNotifications, value);
  }

  void toggleBiometricLock(bool value) {
    state = state.copyWith(biometricLockEnabled: value);
    _save(_kBiometric, value);
  }

  void setMonitoringFrequency(String frequency) {
    state = state.copyWith(monitoringFrequency: frequency);
    _saveString(_kMonitoringFreq, frequency);
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(darkModeEnabled: value);
    _save(_kDarkMode, value);
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
