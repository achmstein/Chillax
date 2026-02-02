import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Get font family based on locale
String getFontFamily(Locale locale) {
  return locale.languageCode == 'ar' ? 'NotoSansArabic' : 'Inter';
}

/// Extension to get font family from context
extension LocaleFontExtension on BuildContext {
  /// Get the font family for the current locale
  String get fontFamily {
    final locale = Localizations.localeOf(this);
    return getFontFamily(locale);
  }
}

/// Theme mode enum
enum AppThemeMode { light, dark, system }

/// Theme state
class ThemeState {
  final AppThemeMode themeMode;

  const ThemeState({this.themeMode = AppThemeMode.light});

  ThemeState copyWith({AppThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  /// Get Forui theme with locale-aware typography
  FThemeData getForuiTheme(BuildContext context, {Locale? locale}) {
    final Brightness brightness;
    switch (themeMode) {
      case AppThemeMode.light:
        brightness = Brightness.light;
        break;
      case AppThemeMode.dark:
        brightness = Brightness.dark;
        break;
      case AppThemeMode.system:
        brightness = MediaQuery.platformBrightnessOf(context);
        break;
    }

    // Get base colors from zinc theme
    final colors = brightness == Brightness.dark
        ? FThemes.zinc.dark.colors
        : FThemes.zinc.light.colors;

    // Get font family based on locale
    final fontFamily = locale != null ? getFontFamily(locale) : 'Inter';

    // Create typography with the correct font family
    // This ensures all text styles use the locale-appropriate font
    final typography = FTypography.inherit(
      colors: colors,
      defaultFontFamily: fontFamily,
    );

    // Create style that inherits from colors and typography
    final style = FStyle.inherit(
      colors: colors,
      typography: typography,
    );

    // Build complete theme - widget styles will inherit from typography
    return FThemeData(
      colors: colors,
      typography: typography,
      style: style,
    );
  }
}

/// Theme notifier
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme() {
    final newMode = state.themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    state = state.copyWith(themeMode: newMode);
  }
}

/// Theme provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

/// Semantic colors - consistent across light/dark mode
class AppColors {
  static const Color successColor = Color(0xFF16A34A); // green-600
  static const Color errorColor = Color(0xFFDC2626); // red-600
  static const Color warningColor = Color(0xFFCA8A04); // yellow-600
}
