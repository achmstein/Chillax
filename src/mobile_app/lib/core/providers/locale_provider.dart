import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeKey = 'app_locale';

/// Cached initial locale loaded before app starts
Locale? _initialLocale;

/// Call this before runApp() to preload the saved locale
Future<void> initializeLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString(_localeKey);
  _initialLocale = savedLocale != null ? Locale(savedLocale) : const Locale('ar');
}

/// Provider for managing the app's locale/language setting
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const List<Locale> supportedLocales = [
    Locale('ar'), // Arabic - default
    Locale('en'), // English
  ];

  @override
  Locale build() {
    // Use preloaded locale or default to Arabic
    return _initialLocale ?? const Locale('ar');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;

    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  void toggleLocale() {
    final newLocale = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    setLocale(newLocale);
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}
