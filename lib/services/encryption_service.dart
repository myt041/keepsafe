import 'dart:convert';
import 'dart:typed_data'; // Add import for Uint8List
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encryptLib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:keepsafe/services/backup_password_service.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Key for storing and retrieving encryption key
  static const String _encryptionKeyStorage = 'encryption_key';

  // Cache the key once loaded
  encryptLib.Key? _cachedKey;

  // Static key for cross-device compatibility (WARNING: less secure but more compatible)
  static const String _staticPassphrase =
      'KeepSafeStaticSecureKey2024'; // DO NOT change this

  EncryptionService._internal() {
    // Initialize the service by loading the key
    _initializeEncryptionKey();
  }

  // Initialize encryption key at startup
  Future<void> _initializeEncryptionKey() async {
    _cachedKey = await _getOrCreateEncryptionKey();
  }

  // Encrypts a string using AES encryption - use ONLY the consistent key
  Future<String> encrypt(String plainText) async {
    // Always use the consistent key for cross-device compatibility
    final key = _getConsistentKey();
    final iv = encryptLib.IV.fromLength(16);

    try {
      debugPrint('Encrypting with consistent key');
      final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return a combined string with iv and encrypted data
      final result = '${iv.base64}:${encrypted.base64}';
      debugPrint('Encryption complete, result length: ${result.length}');

      // Verify encryption worked
      try {
        final testDecrypt = await decrypt(result);
        final testWorked = testDecrypt.isNotEmpty;
        debugPrint(
            'Encryption verification: ${testWorked ? "SUCCESS" : "FAILED"}');
      } catch (e) {
        debugPrint('WARNING: Verification of encryption failed: $e');
      }

      return result;
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  // Decrypts a previously encrypted string
  Future<String> decrypt(String encryptedText) async {
    try {
      // Check if the text contains the expected separator
      if (!encryptedText.contains(':')) {
        // This might be a legacy format or corrupted file
        return _attemptLegacyDecrypt(encryptedText);
      }

      // Split the combined string to get IV and encrypted data
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        // Try legacy format for malformed data
        return _attemptLegacyDecrypt(encryptedText);
      }

      debugPrint('Attempting to decrypt with consistent key first');
      // Always try the consistent key first as that's what we use for export
      try {
        final key = _getConsistentKey();
        final iv = encryptLib.IV.fromBase64(parts[0]);
        final encrypted = encryptLib.Encrypted.fromBase64(parts[1]);

        final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
        final result = encrypter.decrypt(encrypted, iv: iv);

        if (result.isNotEmpty) {
          debugPrint(
              'Decryption with consistent key successful, length: ${result.length}');
          return result;
        }
      } catch (e) {
        debugPrint('Consistent key decryption failed: $e');
      }

      // As a fallback, try the device-specific key
      try {
        final deviceKey = await _ensureKeyIsLoaded();
        final iv = encryptLib.IV.fromBase64(parts[0]);
        final encrypted = encryptLib.Encrypted.fromBase64(parts[1]);

        final encrypter = encryptLib.Encrypter(encryptLib.AES(deviceKey));
        final result = encrypter.decrypt(encrypted, iv: iv);

        if (result.isNotEmpty) {
          debugPrint('Decryption with device key successful');
          return result;
        }
      } catch (e) {
        debugPrint('Device key decryption failed: $e');
      }

      // If we get here, try the legacy approach as a last resort
      return _attemptLegacyDecrypt(encryptedText);
    } catch (e) {
      debugPrint('Error during decryption: $e');
      rethrow;
    }
  }

  // Attempt to decrypt using various legacy approaches
  String _attemptLegacyDecrypt(String encryptedText) {
    debugPrint(
        'Attempting legacy decryption for data:  [38;5;2m [48;5;236m [1m${encryptedText.length} [0m characters');
    // Instead of returning empty data, throw an error
    throw Exception(
        'Legacy decryption failed. This may be a password-protected or corrupted backup.');
  }

  // Create a consistent key that will work across devices
  encryptLib.Key _getConsistentKey() {
    // Create SHA-256 hash of the passphrase to get a consistent 32-byte key
    final List<int> passphraseBytes = utf8.encode(_staticPassphrase);
    final crypto.Digest digest = crypto.sha256.convert(passphraseBytes);
    final Uint8List keyBytes = Uint8List.fromList(digest.bytes);

    return encryptLib.Key(keyBytes);
  }

  // Ensure the key is loaded before use
  Future<encryptLib.Key> _ensureKeyIsLoaded() async {
    _cachedKey ??= await _getOrCreateEncryptionKey();
    return _cachedKey!;
  }

  // Gets or creates an encryption key
  Future<encryptLib.Key> _getOrCreateEncryptionKey() async {
    try {
      // Try to retrieve the existing key
      final storedKey = await _secureStorage.read(key: _encryptionKeyStorage);

      if (storedKey != null) {
        // Use the stored key
        return encryptLib.Key.fromBase64(storedKey);
      } else {
        // Generate a new key if none exists
        final newKey =
            encryptLib.Key.fromSecureRandom(32); // 32 bytes = 256 bits
        await _secureStorage.write(
          key: _encryptionKeyStorage,
          value: newKey.base64,
        );
        return newKey;
      }
    } catch (e) {
      debugPrint('Error creating encryption key: $e, using fallback key');
      // If there's an error, generate a deterministic key of exactly 32 bytes
      return _getConsistentKey();
    }
  }

  // Encrypt data with backup password
  Future<String> encryptWithBackupPassword(
      String plainText, String backupPassword) async {
    try {
      final backupPasswordService = BackupPasswordService();
      final key =
          await backupPasswordService.generateEncryptionKey(backupPassword);
      final iv = encryptLib.IV.fromLength(16);

      debugPrint('Encrypting with backup password');
      final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return a combined string with iv and encrypted data
      final result = '${iv.base64}:${encrypted.base64}';
      debugPrint(
          'Backup password encryption complete, result length: ${result.length}');

      return result;
    } catch (e) {
      debugPrint('Backup password encryption error: $e');
      rethrow;
    }
  }

  // Encrypt data with backup password and specific salt (for cross-device export)
  Future<String> encryptWithBackupPasswordAndSalt(
      String plainText, String backupPassword, String salt) async {
    try {
      final backupPasswordService = BackupPasswordService();
      final key = await backupPasswordService.generateEncryptionKeyWithSalt(
          backupPassword, salt);
      final iv = encryptLib.IV.fromLength(16);

      debugPrint('Encrypting with backup password and salt');
      final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Return a combined string with iv and encrypted data
      final result = '${iv.base64}:${encrypted.base64}';
      debugPrint(
          'Backup password encryption with salt complete, result length: ${result.length}');

      return result;
    } catch (e) {
      debugPrint('Backup password encryption with salt error: $e');
      rethrow;
    }
  }

  // Decrypt data with backup password
  Future<String> decryptWithBackupPassword(
      String encryptedText, String backupPassword) async {
    try {
      // Check if the text contains the expected separator
      if (!encryptedText.contains(':')) {
        throw Exception('Invalid encrypted data format');
      }

      // Split the combined string to get IV and encrypted data
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final backupPasswordService = BackupPasswordService();
      final key =
          await backupPasswordService.generateEncryptionKey(backupPassword);
      final iv = encryptLib.IV.fromBase64(parts[0]);
      final encrypted = encryptLib.Encrypted.fromBase64(parts[1]);

      final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
      final result = encrypter.decrypt(encrypted, iv: iv);

      if (result.isEmpty) {
        throw Exception('Decryption returned empty data');
      }

      debugPrint(
          'Backup password decryption successful, length: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('Backup password decryption error: $e');
      rethrow;
    }
  }

  // Decrypt data with backup password and specific salt (for cross-device import)
  Future<String> decryptWithBackupPasswordAndSalt(
      String encryptedText, String backupPassword, String salt) async {
    try {
      // Check if the text contains the expected separator
      if (!encryptedText.contains(':')) {
        throw Exception('Invalid encrypted data format');
      }

      // Split the combined string to get IV and encrypted data
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final backupPasswordService = BackupPasswordService();
      final key = await backupPasswordService.generateEncryptionKeyWithSalt(
          backupPassword, salt);
      final iv = encryptLib.IV.fromBase64(parts[0]);
      final encrypted = encryptLib.Encrypted.fromBase64(parts[1]);

      final encrypter = encryptLib.Encrypter(encryptLib.AES(key));
      final result = encrypter.decrypt(encrypted, iv: iv);

      if (result.isEmpty) {
        throw Exception('Decryption returned empty data');
      }

      debugPrint(
          'Backup password decryption with salt successful, length: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('Backup password decryption with salt error: $e');
      rethrow;
    }
  }
}
