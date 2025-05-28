import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/screens/home_screen.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:keepsafe/widgets/pin_input.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Increase delay for biometric check to ensure system is fully ready
    Future.delayed(const Duration(seconds: 1), _checkBiometrics);
  }

  Future<void> _checkBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isBiometricsEnabled) {
      try {
        await _authenticateWithBiometrics();
      } catch (e) {
        // Log the error but don't show to user on startup
        debugPrint('Error during startup biometric check: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if biometrics are available before attempting auth
      final biometricsAvailable = authProvider.isBiometricsAvailable;
      if (!biometricsAvailable) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Biometrics not available on this device. Please use your PIN.';
            _isLoading = false;
          });
        }
        return;
      }
      
      // Reset any biometric state that might be persisting from previous attempts
      await Future.delayed(const Duration(milliseconds: 300));
      
      final authenticated = await authProvider.loginWithBiometrics();
      
      if (authenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Biometric authentication failed. Please use your PIN.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Authentication error in login screen: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication error. Please use your PIN.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithPin() async {
    if (_pin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit PIN';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await authProvider.loginWithPin(_pin);
      
      if (authenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
          _pin = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error. Please try again.';
        _pin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPinChanged(String pin) {
    setState(() {
      _pin = pin;
      _errorMessage = '';
    });

    if (pin.length == 4) {
      _loginWithPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hasBiometrics = authProvider.isBiometricsAvailable && 
                         authProvider.isBiometricsEnabled;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter your PIN to unlock',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  PinInput(
                    pinLength: 4,
                    onChanged: _onPinChanged,
                    pin: _pin,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else if (hasBiometrics)
                    ElevatedButton.icon(
                      onPressed: _authenticateWithBiometrics,
                      icon: Icon(
                        authProvider.availableBiometrics.contains(BiometricType.face)
                            ? Icons.face
                            : Icons.fingerprint,
                      ),
                      label: const Text('Use Biometrics'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 