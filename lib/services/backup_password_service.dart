import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encryptLib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BackupPasswordService {
  static final BackupPasswordService _instance =
      BackupPasswordService._internal();
  factory BackupPasswordService() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Key for storing backup password hash
  static const String _backupPasswordHashKey = 'backup_password_hash';
  static const String _backupPasswordSaltKey = 'backup_password_salt';

  // Cache the password hash once loaded
  String? _cachedPasswordHash;
  String? _cachedSalt;

  BackupPasswordService._internal();

  /// Check if a backup password is set
  Future<bool> isBackupPasswordSet() async {
    try {
      final hash = await _secureStorage.read(key: _backupPasswordHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking backup password status: $e');
      return false;
    }
  }

  /// Set a new backup password
  Future<void> setBackupPassword(String password) async {
    try {
      if (password.isEmpty) {
        throw Exception('Backup password cannot be empty');
      }

      // Generate a random salt
      final salt = _generateSalt();

      // Hash the password with salt
      final hashedPassword = _hashPassword(password, salt);

      // Store the hash and salt securely
      await _secureStorage.write(
          key: _backupPasswordHashKey, value: hashedPassword);
      await _secureStorage.write(key: _backupPasswordSaltKey, value: salt);

      // Update cache
      _cachedPasswordHash = hashedPassword;
      _cachedSalt = salt;

      debugPrint('Backup password set successfully');
    } catch (e) {
      debugPrint('Error setting backup password: $e');
      rethrow;
    }
  }

  /// Verify a backup password
  Future<bool> verifyBackupPassword(String password) async {
    try {
      if (password.isEmpty) return false;

      // Get stored hash and salt
      final storedHash = await _secureStorage.read(key: _backupPasswordHashKey);
      final storedSalt = await _secureStorage.read(key: _backupPasswordSaltKey);

      if (storedHash == null || storedSalt == null) {
        return false;
      }

      // Hash the provided password with stored salt
      final hashedPassword = _hashPassword(password, storedSalt);

      // Compare hashes
      return hashedPassword == storedHash;
    } catch (e) {
      debugPrint('Error verifying backup password: $e');
      return false;
    }
  }

  /// Generate encryption key from backup password
  Future<encryptLib.Key> generateEncryptionKey(String password) async {
    try {
      // Load cached values if not loaded
      await _loadCachedValues();

      // Get the stored salt
      final salt = _cachedSalt ?? '';

      // Create a combined string of password + salt + app-specific identifier
      final combinedString = 'KeepSafeBackup:$password:$salt:2024';

      // Create SHA-256 hash to get a consistent 32-byte key
      final List<int> combinedBytes = utf8.encode(combinedString);
      final crypto.Digest digest = crypto.sha256.convert(combinedBytes);
      final Uint8List keyBytes = Uint8List.fromList(digest.bytes);

      return encryptLib.Key(keyBytes);
    } catch (e) {
      debugPrint('Error generating encryption key: $e');
      rethrow;
    }
  }

  /// Generate encryption key from backup password with specific salt (for cross-device import)
  Future<encryptLib.Key> generateEncryptionKeyWithSalt(
      String password, String salt) async {
    try {
      // Create a combined string of password + provided salt + app-specific identifier
      final combinedString = 'KeepSafeBackup:$password:$salt:2024';

      // Create SHA-256 hash to get a consistent 32-byte key
      final List<int> combinedBytes = utf8.encode(combinedString);
      final crypto.Digest digest = crypto.sha256.convert(combinedBytes);
      final Uint8List keyBytes = Uint8List.fromList(digest.bytes);

      return encryptLib.Key(keyBytes);
    } catch (e) {
      debugPrint('Error generating encryption key with salt: $e');
      rethrow;
    }
  }

  /// Get the current salt (for embedding in backup files)
  Future<String> getCurrentSalt() async {
    await _loadCachedValues();
    return _cachedSalt ?? '';
  }

  /// Clear backup password (for testing or reset)
  Future<void> clearBackupPassword() async {
    try {
      await _secureStorage.delete(key: _backupPasswordHashKey);
      await _secureStorage.delete(key: _backupPasswordSaltKey);
      _cachedPasswordHash = null;
      _cachedSalt = null;
      debugPrint('Backup password cleared');
    } catch (e) {
      debugPrint('Error clearing backup password: $e');
      rethrow;
    }
  }

  /// Generate a random salt
  String _generateSalt() {
    final random = encryptLib.Key.fromSecureRandom(16);
    return random.base64;
  }

  /// Hash password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    final combinedString = '$password:$salt:KeepSafeBackup2024';
    final List<int> bytes = utf8.encode(combinedString);
    final crypto.Digest digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  /// Load cached values
  Future<void> _loadCachedValues() async {
    if (_cachedPasswordHash == null) {
      _cachedPasswordHash =
          await _secureStorage.read(key: _backupPasswordHashKey);
    }
    if (_cachedSalt == null) {
      _cachedSalt = await _secureStorage.read(key: _backupPasswordSaltKey);
    }
  }
}
