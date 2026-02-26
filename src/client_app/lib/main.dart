import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'features/notifications/services/notification_service.dart';
import 'features/orders/services/order_service.dart';
import 'features/rooms/services/room_service.dart';

void main() async {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load saved locale before app starts
  await initializeLocale();

  // Initialize Firebase before setting up Crashlytics handlers
  try {
    await Firebase.initializeApp();

    // Send Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Send async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Firebase not configured - app will work without crash reporting
  }

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
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _cancelSignalRSubscriptions();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize auth FIRST — Firebase/FCM must never block the UI
      await ref.read(authServiceProvider.notifier).initialize();

      // Connect SignalR if authenticated
      final authState = ref.read(authServiceProvider);
      if (authState.isAuthenticated) {
        if (authState.userId != null) {
          FirebaseCrashlytics.instance.setUserIdentifier(authState.userId!);
        }
        _connectSignalR();
        _wasAuthenticated = true;
      }
    } catch (e, stack) {
      debugPrint('App initialization error: $e\n$stack');
    } finally {
      // ALWAYS remove splash screen, even if initialization fails
      FlutterNativeSplash.remove();
    }

    // Initialize Firebase/FCM in the background — never blocks the UI
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      await ref.read(firebaseServiceProvider).initialize();

      // Register for push notifications if already authenticated
      if (ref.read(authServiceProvider).isAuthenticated) {
        _registerForOrderNotifications();
      }
    } catch (e) {
      debugPrint('Firebase messaging initialization failed: $e');
    }
  }

  void _cancelSignalRSubscriptions() {
    for (final sub in _signalRSubscriptions) {
      sub.cancel();
    }
    _signalRSubscriptions.clear();
  }

  void _registerForOrderNotifications() {
    // Fire-and-forget: register device for order status push notifications
    final locale = ref.read(localeProvider);
    final lang = locale?.languageCode ?? 'en';
    ref.read(notificationRepositoryProvider).registerForOrderNotifications(
      preferredLanguage: lang,
    );

    // Re-register when FCM token refreshes mid-session
    ref.read(firebaseServiceProvider).onTokenRefresh((_) {
      ref.read(notificationRepositoryProvider).registerForOrderNotifications(
        preferredLanguage: ref.read(localeProvider)?.languageCode ?? 'en',
      );
    });
  }

  void _connectSignalR() {
    final signalR = ref.read(signalRServiceProvider);
    signalR.connect();

    // Listen for realtime events and refresh providers
    _signalRSubscriptions.add(
      signalR.onRoomStatusChanged.listen((_) {
        ref.invalidate(roomsProvider);
        ref.read(mySessionsProvider.notifier).refresh();
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
    final authState = ref.watch(authServiceProvider);
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    // React to auth state changes (e.g. first login, logout)
    if (authState.isAuthenticated && !_wasAuthenticated) {
      _wasAuthenticated = true;
      // Set user ID on Crashlytics
      if (authState.userId != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(authState.userId!);
      }
      _connectSignalR();
      _registerForOrderNotifications();
    } else if (!authState.isAuthenticated && _wasAuthenticated) {
      _wasAuthenticated = false;
      _cancelSignalRSubscriptions();
    }

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
