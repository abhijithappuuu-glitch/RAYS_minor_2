import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rakshak_ai/core/di/injection.dart';
import 'package:rakshak_ai/data/datasources/local/isar_database.dart';
import 'package:rakshak_ai/core/security/encryption_service.dart';

/// Service for exporting and deleting user data (GDPR-compliant)
class DataExportService {
  final IsarDatabase _database;
  final EncryptionService _encryption;

  DataExportService({
    IsarDatabase? database,
    EncryptionService? encryption,
  })  : _database = database ?? getIt<IsarDatabase>(),
        _encryption = encryption ?? getIt<EncryptionService>();

  /// Export all user data as JSON file
  Future<String> exportAllData() async {
    final stressBox = await _database.stressBox;
    final usageBox = await _database.usageBox;
    final healthBox = await _database.healthBox;

    final stressRecords = stressBox.values.map((r) => {
          'stress_score': r.stressScore,
          'risk_level': r.riskLevel,
          'confidence': r.confidence,
          'timestamp': r.timestamp.toIso8601String(),
        }).toList();

    final usageRecords = usageBox.values.map((r) => {
          'social_minutes': r.socialMinutes,
          'pickup_count': r.pickupCount,
          'late_night_usage': r.lateNightUsage,
          'doom_scroll_flag': r.doomScrollFlag,
          'total_screen_minutes': r.totalScreenMinutes,
          'collected_at': r.collectedAt.toIso8601String(),
        }).toList();

    final healthRecords = healthBox.values.map((r) => {
          'sleep_minutes': r.sleepMinutes,
          'exercise_minutes': r.exerciseMinutes,
          'resting_heart_rate': r.restingHeartRate,
          'steps': r.steps,
          'collected_at': r.collectedAt.toIso8601String(),
        }).toList();

    final exportData = {
      'app': 'RAYS',
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'data': {
        'stress_history': stressRecords,
        'usage_history': usageRecords,
        'health_history': healthRecords,
        'summary': {
          'total_stress_records': stressRecords.length,
          'total_usage_records': usageRecords.length,
          'total_health_records': healthRecords.length,
        }
      }
    };

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/rakshak_export_$timestamp.json');

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Share exported data file
  Future<void> shareExportedData() async {
    final filePath = await exportAllData();
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'RAYS Data Export',
      text: 'Your RAYS data export',
    );
  }

  /// Delete all user data
  Future<void> deleteAllData() async {
    await _database.clearAll();
  }

  /// Get data summary for UI
  Future<Map<String, int>> getDataSummary() async {
    final stressCount = await _database.getTotalRecordCount();
    final usageBox = await _database.usageBox;
    final healthBox = await _database.healthBox;

    return {
      'stress_records': stressCount,
      'usage_records': usageBox.length,
      'health_records': healthBox.length,
    };
  }

  /// Export data in encrypted format
  Future<String> exportEncryptedData() async {
    final filePath = await exportAllData();
    final file = File(filePath);
    final content = await file.readAsString();

    final encrypted = await _encryption.encrypt(content);

    final encryptedFile = File('${filePath.replaceAll('.json', '')}_encrypted.enc');
    await encryptedFile.writeAsString(encrypted);

    // Delete unencrypted file
    await file.delete();

    return encryptedFile.path;
  }
}

