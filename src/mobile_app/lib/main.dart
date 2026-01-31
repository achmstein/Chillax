import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load saved locale before app starts
  await initializeLocale();

  runApp(
    const ProviderScope(
      child: ChillaxApp(),
    ),
  );
}

/// Main application widget0
class ChillaxApp extends ConsumerStatefulWidget {
  const ChillaxApp({super.key});

  @override
  ConsumerState<ChillaxApp> createState() => _ChillaxAppState();
}

class _ChillaxAppState extends ConsumerState<ChillaxApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase for push notifications (may fail if not configured)
    await ref.read(firebaseServiceProvider).initialize();

    // Initialize auth service
    await ref.read(authServiceProvider.notifier).initialize();

    // Remove the native splash screen after initialization
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    final fontFamily = getFontFamily(locale);

    return MaterialApp.router(
      title: 'Chillax',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        fontFamily: fontFamily,
        textTheme: getLocalizedTextTheme(locale, isDark: false),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: fontFamily,
        textTheme: getLocalizedTextTheme(locale, isDark: true),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeState.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : themeState.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;

        return FTheme(
          data: themeState.getForuiTheme(context, locale: locale),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: fontFamily,
              color: textColor,
              fontSize: 14,
            ),
            child: FToaster(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
