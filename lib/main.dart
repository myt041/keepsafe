import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keepsafe/screens/splash_screen.dart';
import 'package:keepsafe/providers/auth_provider.dart';
import 'package:keepsafe/providers/data_provider.dart';
import 'package:keepsafe/providers/theme_provider.dart';
import 'package:keepsafe/providers/subscription_provider.dart';
import 'package:keepsafe/utils/theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app after a brief delay to ensure system services are ready
  await Future.delayed(const Duration(milliseconds: 300));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'KeepSafe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
