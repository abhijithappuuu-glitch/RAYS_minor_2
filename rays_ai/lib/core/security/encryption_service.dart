import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyAlias = 'rakshak_master_key';
  // No persistent IV — a fresh 16-byte IV is generated per encrypt() call.
  
  final FlutterSecureStorage _secureStorage;
  
  EncryptionService(this._secureStorage);
  
  Future<void> initialize() async {
    // Generate and store master key if not exists.
    // No IV is persisted — a fresh IV is generated on every encrypt() call.
    final existingKey = await _secureStorage.read(key: _keyAlias);
    if (existingKey == null) {
      final key = Key.fromSecureRandom(32); // AES-256
      await _secureStorage.write(
        key: _keyAlias,
        value: base64.encode(key.bytes),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    }
  }
  
  /// Encrypts [plainText] using AES-256-GCM with a freshly generated IV.
  /// Output format: base64( iv(16 bytes) || ciphertext )
  Future<String> encrypt(String plainText) async {
    final key = await _getKey();
    final iv = IV.fromSecureRandom(16); // unique per call — never reused
    
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Prepend the IV so decrypt() can recover it without storing it
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64.encode(combined);
  }
  
  /// Decrypts a value produced by [encrypt].
  /// Expects base64( iv(16 bytes) || ciphertext ).
  Future<String> decrypt(String encryptedText) async {
    final key = await _getKey();
    final combined = base64.decode(encryptedText);
    
    // First 16 bytes are the IV, the rest is the ciphertext
    final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = Uint8List.fromList(combined.sublist(16));
    
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(Encrypted(cipherBytes), iv: iv);
  }
  
  Future<Key> _getKey() async {
    final keyString = await _secureStorage.read(key: _keyAlias);
    return Key(base64.decode(keyString!));
  }
  
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );
  
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
}
