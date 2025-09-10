import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isSystemDark = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return _isSystemDark;
    }
    return _themeMode == ThemeMode.dark;
  }

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System (${_isSystemDark ? 'Dark' : 'Light'})';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  ThemeProvider() {
    _checkSystemTheme();
  }

  void _checkSystemTheme() {
    // Check if the platform supports dark mode
    try {
      // This is a simple approach - in a real app you might want to use
      // MediaQuery or PlatformBrightness for more accurate detection
      final hour = DateTime.now().hour;
      _isSystemDark = hour < 6 || hour > 18; // 6PM to 6AM is "dark"
    } catch (e) {
      _isSystemDark = false; // Fallback to light mode
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      // If currently following system, switch to opposite of system
      _themeMode = _isSystemDark ? ThemeMode.light : ThemeMode.dark;
    } else {
      // If not following system, toggle between light/dark
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void followSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Call this method when the app starts to get the actual system theme
  void updateSystemTheme(Brightness platformBrightness) {
    _isSystemDark = platformBrightness == Brightness.dark;
    notifyListeners();
  }
}