import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefsKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Get from system
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // Initialize theme preference
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themePrefsKey);
      
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      }
      // If no saved preference, keep the default (ThemeMode.dark)
      
      notifyListeners();
    } catch (e) {
      // If there's an error, use dark theme as default
      _themeMode = ThemeMode.dark;
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefsKey, mode.index);
    } catch (e) {
      // Ignore error
    }
    
    notifyListeners();
  }
} 