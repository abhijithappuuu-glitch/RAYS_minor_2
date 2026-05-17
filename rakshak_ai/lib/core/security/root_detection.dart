import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class RootDetectionService {
  static Future<bool> isDeviceRooted() async {
    if (Platform.isAndroid) {
      return await _checkAndroidRoot();
    }
    return false;
  }
  
  static Future<bool> _checkAndroidRoot() async {
    // Check for common root files
    final rootFiles = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];
    
    for (final path in rootFiles) {
      if (await File(path).exists()) {
        return true;
      }
    }
    
    // Check for build tags
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final buildTags = androidInfo.tags;
    
    if (buildTags.contains('test-keys')) {
      return true;
    }
    
    return false;
  }
  
  static Future<bool> isEmulator() async {
    if (!Platform.isAndroid) return false;
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    final emulatorIndicators = [
      androidInfo.model.contains('google_sdk'),
      androidInfo.model.contains('Emulator'),
      androidInfo.model.contains('Android SDK'),
      androidInfo.manufacturer.contains('Genymotion'),
      androidInfo.brand.startsWith('generic'),
      androidInfo.device.startsWith('generic'),
      androidInfo.product.contains('sdk'),
    ];
    
    return emulatorIndicators.any((indicator) => indicator);
  }
}
