import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// App theme configuration using Forui
class AppTheme {
  /// Light theme - Violet for admin app
  static FThemeData get light => FThemes.violet.light;

  /// Dark theme - Violet for admin app
  static FThemeData get dark => FThemes.violet.dark;

  /// Get theme based on brightness
  static FThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Theme mode notifier for switching between light and dark
class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setThemeMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
