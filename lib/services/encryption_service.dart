import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Key? _cachedKey;

  EncryptionService._internal() {
    // Initialize the service by loading the key
    _initializeEncryptionKey();
  }
  
  // Initialize encryption key at startup
  Future<void> _initializeEncryptionKey() async {
    _cachedKey = await _getOrCreateEncryptionKey();
  }

  // Encrypts a string using AES encryption
  Future<String> encrypt(String plainText) async {
    final key = await _ensureKeyIsLoaded();
    final iv = IV.fromLength(16);
    
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Return a combined string with iv and encrypted data
    return '${iv.base64}:${encrypted.base64}';
  }

  // Decrypts a previously encrypted string
  Future<String> decrypt(String encryptedText) async {
    final key = await _ensureKeyIsLoaded();
    
    // Split the combined string to get IV and encrypted data
    final parts = encryptedText.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
  
  // Ensure the key is loaded before use
  Future<Key> _ensureKeyIsLoaded() async {
    if (_cachedKey == null) {
      _cachedKey = await _getOrCreateEncryptionKey();
    }
    return _cachedKey!;
  }

  // Gets or creates an encryption key
  Future<Key> _getOrCreateEncryptionKey() async {
    try {
      // Try to retrieve the existing key
      final storedKey = await _secureStorage.read(key: _encryptionKeyStorage);
      
      if (storedKey != null) {
        // Use the stored key
        return Key.fromBase64(storedKey);
      } else {
        // Generate a new key if none exists
        final newKey = Key.fromSecureRandom(32); // 32 bytes = 256 bits
        await _secureStorage.write(
          key: _encryptionKeyStorage,
          value: newKey.base64,
        );
        return newKey;
      }
    } catch (e) {
      // If there's an error, generate a temporary key (not ideal, but allows the app to function)
      // This key MUST be 32 bytes (256 bits) for AES-256
      return Key.fromUtf8('KeepSafeTemporaryEncryptionKey32Bytes!');
    }
  }
} 