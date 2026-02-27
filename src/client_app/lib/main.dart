import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initializeLocale();

  // Initialize Firebase before setting up Crashlytics handlers
  try {
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

class ChillaxApp extends ConsumerStatefulWidget {
  const ChillaxApp({super.key});

  @override
  ConsumerState<ChillaxApp> createState() => _ChillaxAppState();
}

class _ChillaxAppState extends ConsumerState<ChillaxApp>
    with WidgetsBindingObserver {
  final List<StreamSubscription> _signalRSubscriptions = [];
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelSignalRSubscriptions();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wasAuthenticated) {
      ref.read(signalRServiceProvider).reconnectIfNeeded();
    }
  }

  Future<void> _initializeApp() async {
    try {
      await ref.read(authServiceProvider.notifier).initialize();

      final authState = ref.read(authServiceProvider);
      if (authState.isAuthenticated) {
        _connectSignalR();
        _wasAuthenticated = true;
      }
    } catch (e, stack) {
      debugPrint('App initialization error: $e\n$stack');
    } finally {
      FlutterNativeSplash.remove();
    }

    // Initialize Firebase messaging in background (never blocks UI)
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      await ref.read(firebaseServiceProvider).initialize();

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
    final lang = ref.read(localeProvider)?.languageCode ?? 'en';
    ref.read(notificationRepositoryProvider).registerForOrderNotifications(
      preferredLanguage: lang,
    );

    ref.read(firebaseServiceProvider).onTokenRefresh((_) {
      ref.read(notificationRepositoryProvider).registerForOrderNotifications(
        preferredLanguage: ref.read(localeProvider)?.languageCode ?? 'en',
      );
    });
  }

  void _connectSignalR() {
    final signalR = ref.read(signalRServiceProvider);
    signalR.connect();

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

    if (authState.isAuthenticated && !_wasAuthenticated) {
      _wasAuthenticated = true;
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
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
