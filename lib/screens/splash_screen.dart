import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/providers/subscription_provider.dart';
import 'package:keepsafe/screens/auth/login_screen.dart';
import 'package:keepsafe/screens/auth/setup_screen.dart';
import 'package:keepsafe/screens/home_screen.dart';
import 'package:keepsafe/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // Initialize auth state and subscription provider, then navigate accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);

      // Initialize both providers in parallel
      await Future.wait([
        authProvider.initialize(),
        subscriptionProvider.initialize(),
      ]);

      _navigateToNextScreen(authProvider.status);
    });
  }

  void _navigateToNextScreen(AuthStatus status) {
    if (status == AuthStatus.initializing) return;

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      Widget nextScreen;

      switch (status) {
        case AuthStatus.firstLaunch:
          nextScreen = const SetupScreen();
          break;
        case AuthStatus.unauthenticated:
          nextScreen = const LoginScreen();
          break;
        case AuthStatus.authenticated:
          nextScreen = const HomeScreen();
          break;
        default:
          nextScreen = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/app_logo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'KeepSafe',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal secure vault',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
