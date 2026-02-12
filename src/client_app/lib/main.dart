import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/signalr_service.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/orders/services/order_service.dart';
import 'features/rooms/services/room_service.dart';

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
  final List<StreamSubscription> _signalRSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    for (final sub in _signalRSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase for push notifications (may fail if not configured)
    await ref.read(firebaseServiceProvider).initialize();

    // Initialize auth service
    await ref.read(authServiceProvider.notifier).initialize();

    // Remove the native splash screen after initialization
    FlutterNativeSplash.remove();

    // Connect SignalR if authenticated
    if (ref.read(authServiceProvider).isAuthenticated) {
      _connectSignalR();
    }
  }

  void _connectSignalR() {
    final signalR = ref.read(signalRServiceProvider);
    signalR.connect();

    // Listen for realtime events and refresh providers
    _signalRSubscriptions.add(
      signalR.onRoomStatusChanged.listen((_) {
        ref.invalidate(roomsProvider);
      }),
    );
    _signalRSubscriptions.add(
      signalR.onOrderStatusChanged.listen((_) {
        ref.read(ordersProvider.notifier).refresh();
      }),
    );
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: getFontFamily(locale),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: getFontFamily(locale),
      ),
      themeMode: themeState.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : themeState.themeMode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      builder: (context, child) {
        return FTheme(
          data: themeState.getForuiTheme(context, locale: locale),
          child: FToaster(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
