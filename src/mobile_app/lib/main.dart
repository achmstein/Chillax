import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/theme_provider.dart';

void main() {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

    return MaterialApp.router(
      title: 'Chillax',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supportedLocales,
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: FTheme(
            data: themeState.getForuiTheme(context),
            child: FToaster(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
