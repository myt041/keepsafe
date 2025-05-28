import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/screens/home_screen.dart';
import 'package:keepsafe/utils/theme.dart';
import 'package:keepsafe/widgets/pin_input.dart';
import 'package:local_auth/local_auth.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String _pin = '';
  String _confirmPin = '';
  bool _showError = false;
  bool _useBiometrics = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPinChanged(String pin) {
    setState(() {
      _pin = pin;
      _showError = false;
    });

    if (pin.length == 4) {
      _nextPage();
    }
  }

  void _onConfirmPinChanged(String pin) {
    setState(() {
      _confirmPin = pin;
      _showError = false;
    });

    if (pin.length == 4) {
      _validatePins();
    }
  }

  void _validatePins() {
    if (_pin == _confirmPin) {
      _nextPage();
    } else {
      setState(() {
        _showError = true;
        _confirmPin = '';
      });
    }
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Set PIN
      await authProvider.setupPinCode(_pin);
      
      // Enable biometrics if chosen
      if (_useBiometrics) {
        await authProvider.toggleBiometrics(true);
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _showError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hasBiometrics = authProvider.isBiometricsAvailable;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentStep
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildCreatePinPage(),
                  _buildConfirmPinPage(),
                  if (hasBiometrics) _buildBiometricsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.security,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Welcome to KeepSafe',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Your secure vault for storing confidential information.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePinPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.pin,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 30),
            Text(
              'Create Your PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This PIN will be used to unlock your app.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            PinInput(
              pinLength: 4,
              onChanged: _onPinChanged,
              pin: _pin,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmPinPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 30),
            Text(
              'Confirm Your PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Please enter your PIN again to confirm.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            PinInput(
              pinLength: 4,
              onChanged: _onConfirmPinChanged,
              pin: _confirmPin,
            ),
            const SizedBox(height: 20),
            if (_showError)
              Text(
                'PINs do not match. Please try again.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricsPage() {
    final authProvider = Provider.of<AuthProvider>(context);
    final hasFace = authProvider.availableBiometrics.contains(BiometricType.face);
    final hasFingerprint = authProvider.availableBiometrics.contains(BiometricType.fingerprint);
    
    String biometricType = 'Biometric';
    IconData biometricIcon = Icons.fingerprint;
    
    if (hasFace && !hasFingerprint) {
      biometricType = 'Face ID';
      biometricIcon = Icons.face;
    } else if (!hasFace && hasFingerprint) {
      biometricType = 'Fingerprint';
      biometricIcon = Icons.fingerprint;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            Icon(
              biometricIcon,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 30),
            Text(
              'Enable $biometricType',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Would you like to use $biometricType to unlock the app?',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SwitchListTile(
              title: Text('Use $biometricType'),
              value: _useBiometrics,
              onChanged: (value) {
                setState(() {
                  _useBiometrics = value;
                });
              },
              secondary: Icon(biometricIcon),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _finishSetup,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Complete Setup'),
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
} 