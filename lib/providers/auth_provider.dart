import 'package:flutter/foundation.dart';
import 'package:keepsafe/services/auth_service.dart';
import 'package:local_auth/local_auth.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  firstLaunch,
  authenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initializing;
  bool _isBiometricsAvailable = false;
  bool _isBiometricsEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Getters
  AuthStatus get status => _status;
  bool get isBiometricsAvailable => _isBiometricsAvailable;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  
  // Initialize authentication state
  Future<void> initialize() async {
    final isFirstLaunch = await _authService.isFirstLaunch();
    
    if (isFirstLaunch) {
      _status = AuthStatus.firstLaunch;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    
    // Check biometrics availability
    _isBiometricsAvailable = await _authService.isBiometricsAvailable();
    _availableBiometrics = await _authService.getAvailableBiometrics();
    _isBiometricsEnabled = await _authService.isBiometricsEnabled();
    
    notifyListeners();
  }
  
  // Setup a new PIN code during first launch
  Future<void> setupPinCode(String pin) async {
    await _authService.setPinCode(pin);
    await _authService.completeFirstLaunch();
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
  
  // Login with PIN code
  Future<bool> loginWithPin(String pin) async {
    final isValid = await _authService.validatePinCode(pin);
    
    if (isValid) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    
    return isValid;
  }
  
  // Login with biometrics
  Future<bool> loginWithBiometrics() async {
    try {
      debugPrint('Starting biometric login flow');
      
      if (!_isBiometricsEnabled) {
        debugPrint('Biometrics not enabled in settings');
        return false;
      }

      // Refresh biometrics availability checks
      _isBiometricsAvailable = await _authService.isBiometricsAvailable();
      debugPrint('Biometrics available: $_isBiometricsAvailable');
      
      if (!_isBiometricsAvailable) {
        return false;
      }
      
      // Get available biometrics
      _availableBiometrics = await _authService.getAvailableBiometrics();
      debugPrint('Available biometrics: $_availableBiometrics');
      
      if (_availableBiometrics.isEmpty) {
        debugPrint('No biometrics available on device');
        return false;
      }
      
      // Attempt authentication
      final isAuthenticated = await _authService.authenticateWithBiometrics();
      debugPrint('Biometric authentication result: $isAuthenticated');
      
      if (isAuthenticated) {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error in loginWithBiometrics: $e');
      return false;
    }
  }
  
  // Toggle biometrics authentication
  Future<void> toggleBiometrics(bool enabled) async {
    // First check if biometrics are available
    _isBiometricsAvailable = await _authService.isBiometricsAvailable();
    
    if (enabled && !_isBiometricsAvailable) {
      throw Exception('Biometrics not available on this device');
    }
    
    await _authService.setBiometricsEnabled(enabled);
    _isBiometricsEnabled = enabled;
    notifyListeners();
  }
  
  // Check if PIN is already set
  Future<bool> isPinSet() async {
    return await _authService.isPinCodeSet();
  }
  
  // Change PIN code
  Future<void> changePinCode(String oldPin, String newPin) async {
    final isValid = await _authService.validatePinCode(oldPin);
    
    if (isValid) {
      await _authService.setPinCode(newPin);
      notifyListeners();
    } else {
      throw Exception('Invalid PIN code');
    }
  }
  
  // Logout
  void logout() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  // For development only - reset authentication settings
  Future<void> resetAuth() async {
    await _authService.resetAuthentication();
    await initialize();
  }
} 