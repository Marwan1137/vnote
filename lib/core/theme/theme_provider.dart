import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Initialize and load saved theme
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadThemeFromPrefs();
    _isInitialized = true;
  }

  void toggleTheme() {
    // When user manually toggles, switch between light and dark
    // If currently system, determine based on current brightness
    if (_themeMode == ThemeMode.system) {
      // Default to dark when toggling from system
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');

    if (themeModeString != null) {
      // User has set a preference
      if (themeModeString == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeModeString == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    } else {
      // No preference saved, use system theme
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;

    if (_themeMode == ThemeMode.dark) {
      themeModeString = 'dark';
    } else if (_themeMode == ThemeMode.light) {
      themeModeString = 'light';
    } else {
      themeModeString = 'system';
    }

    await prefs.setString('themeMode', themeModeString);
  }
}
