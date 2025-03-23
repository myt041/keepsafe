import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  // Keys for storing preferences
  static const String _pinCodeKey = 'pin_code';
  static const String _useBiometricsKey = 'use_biometrics';
  static const String _isFirstLaunchKey = 'is_first_launch';
  
  // Check if device supports biometric authentication
  Future<bool> isBiometricsAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      // First check if device is capable of checking biometrics
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        debugPrint('Biometrics not available or not supported');
        return false;
      }
      
      // Get available biometrics and customize the message
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      String reason = 'Authenticate to access your data';
      
      if (availableBiometrics.contains(BiometricType.face)) {
        reason = 'Scan your face to continue';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        reason = 'Scan your fingerprint to continue';
      }
      
      // Authenticate with biometrics
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      
      debugPrint('Biometric authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Error during biometric authentication: ${e.message}, code: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }
  
  // Set PIN code
  Future<void> setPinCode(String pin) async {
    await _secureStorage.write(key: _pinCodeKey, value: pin);
  }
  
  // Validate PIN code
  Future<bool> validatePinCode(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinCodeKey);
    return storedPin == pin;
  }
  
  // Set biometrics preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricsKey, enabled);
  }
  
  // Check if biometrics is enabled
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useBiometricsKey) ?? false;
  }
  
  // Check if this is the first launch of the app
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  // Set first launch to false after initial setup
  Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }
  
  // Check if PIN is set
  Future<bool> isPinCodeSet() async {
    final pin = await _secureStorage.read(key: _pinCodeKey);
    return pin != null && pin.isNotEmpty;
  }
  
  // Reset all authentication settings (for development)
  Future<void> resetAuthentication() async {
    await _secureStorage.delete(key: _pinCodeKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricsKey, false);
    await prefs.setBool(_isFirstLaunchKey, true);
  }
} 