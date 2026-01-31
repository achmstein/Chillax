import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

/// Returns the appropriate font family based on locale
String getFontFamily(Locale locale) {
  return locale.languageCode == 'ar' ? 'NotoSansArabic' : 'Inter';
}

/// Extension on BuildContext for easy access to locale-aware font
extension LocaleFontExtension on BuildContext {
  /// Get the font family for the current locale
  String get fontFamily {
    final locale = Localizations.localeOf(this);
    return getFontFamily(locale);
  }

  /// Create a TextStyle with the correct font family for the current locale
  TextStyle get localizedTextStyle => TextStyle(fontFamily: fontFamily);

  /// Merge a TextStyle with the locale's font family
  TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }
}

/// Creates a TextTheme with the appropriate font family for the locale
TextTheme getLocalizedTextTheme(Locale locale, {bool isDark = false}) {
  final fontFamily = getFontFamily(locale);
  final baseColor = isDark ? Colors.white : Colors.black;

  return TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, color: baseColor),
    displayMedium: TextStyle(fontFamily: fontFamily, color: baseColor),
    displaySmall: TextStyle(fontFamily: fontFamily, color: baseColor),
    headlineLarge: TextStyle(fontFamily: fontFamily, color: baseColor),
    headlineMedium: TextStyle(fontFamily: fontFamily, color: baseColor),
    headlineSmall: TextStyle(fontFamily: fontFamily, color: baseColor),
    titleLarge: TextStyle(fontFamily: fontFamily, color: baseColor),
    titleMedium: TextStyle(fontFamily: fontFamily, color: baseColor),
    titleSmall: TextStyle(fontFamily: fontFamily, color: baseColor),
    bodyLarge: TextStyle(fontFamily: fontFamily, color: baseColor),
    bodyMedium: TextStyle(fontFamily: fontFamily, color: baseColor),
    bodySmall: TextStyle(fontFamily: fontFamily, color: baseColor),
    labelLarge: TextStyle(fontFamily: fontFamily, color: baseColor),
    labelMedium: TextStyle(fontFamily: fontFamily, color: baseColor),
    labelSmall: TextStyle(fontFamily: fontFamily, color: baseColor),
  );
}

class ThemeState {
  final AppThemeMode themeMode;
  final bool isLoading;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.isLoading = true,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  FThemeData getForuiTheme(BuildContext context, {Locale? locale}) {
    FThemeData baseTheme;
    switch (themeMode) {
      case AppThemeMode.light:
        baseTheme = FThemes.zinc.light;
        break;
      case AppThemeMode.dark:
        baseTheme = FThemes.zinc.dark;
        break;
      case AppThemeMode.system:
        final brightness = MediaQuery.platformBrightnessOf(context);
        baseTheme = brightness == Brightness.dark
            ? FThemes.zinc.dark
            : FThemes.zinc.light;
        break;
    }

    // Apply locale-specific font if provided
    if (locale != null) {
      final fontFamily = getFontFamily(locale);
      return baseTheme.copyWith(
        typography: FTypography.inherit(
          colors: baseTheme.colors,
          defaultFontFamily: fontFamily,
        ),
      );
    }

    return baseTheme;
  }

  String get displayName {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeState build() {
    _loadTheme();
    return const ThemeState();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      AppThemeMode mode = AppThemeMode.system;
      if (savedTheme != null) {
        mode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedTheme,
          orElse: () => AppThemeMode.system,
        );
      }

      state = state.copyWith(themeMode: mode, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      // Ignore save errors
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
