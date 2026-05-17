import 'package:flutter/services.dart';

/// Platform channel bridge for native Android/iOS features
class PlatformChannels {
  static const MethodChannel _usageChannel =
      MethodChannel('rakshak.ai/usage_stats');

  /// Get detailed usage statistics from native Android
  static Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final result =
          await _usageChannel.invokeMethod<Map<dynamic, dynamic>>('getUsageStats');
      return result?.cast<String, dynamic>();
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Check if usage stats permission is granted
  static Future<bool> hasUsagePermission() async {
    try {
      final result = await _usageChannel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open system settings to grant usage stats permission
  static Future<void> requestUsagePermission() async {
    try {
      await _usageChannel.invokeMethod('requestPermission');
    } on PlatformException catch (_) {
      // Silently handle
    }
  }
}
