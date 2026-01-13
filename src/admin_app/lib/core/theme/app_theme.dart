import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// App theme configuration using Forui - zinc theme (black) to match mobile app
class AppTheme {
  /// Light theme - Zinc (black) for admin app
  static FThemeData get light => FThemes.zinc.light;

  /// Dark theme - Zinc (black) for admin app
  static FThemeData get dark => FThemes.zinc.dark;

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
