import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/signalr_service.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';
import 'features/service_requests/providers/service_requests_provider.dart';
import 'features/orders/providers/orders_provider.dart';
import 'features/rooms/providers/rooms_provider.dart';
import 'l10n/app_localizations.dart';

class ChillaxAdminApp extends ConsumerStatefulWidget {
  const ChillaxAdminApp({super.key});

  @override
  ConsumerState<ChillaxAdminApp> createState() => _ChillaxAdminAppState();
}

class _ChillaxAdminAppState extends ConsumerState<ChillaxAdminApp> with WidgetsBindingObserver {
  final List<StreamSubscription> _signalRSubscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _setupFCMHandlers();
  }

  @override
  void dispose() {
    for (final sub in _signalRSubscriptions) {
      sub.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authService = ref.read(authServiceProvider.notifier);
      // Proactively refresh token on app resume (may have expired while in background)
      authService.refreshToken();
      // Re-register notifications on app resume (FCM token may have changed)
      authService.reregisterNotifications();
    }
  }

  Future<void> _initializeApp() async {
    // Initialize auth service
    await ref.read(authServiceProvider.notifier).initialize();
    // Remove the native splash screen after auth is initialized
    FlutterNativeSplash.remove();

    // Connect SignalR if authenticated
    final authState = ref.read(authServiceProvider);
    if (authState.isAuthenticated) {
      // Set user ID on Crashlytics so crashes are tied to users
      if (authState.userId != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(authState.userId!);
      }
      _connectSignalR();
    }
  }

  void _connectSignalR() {
    final signalR = ref.read(signalRServiceProvider);
    signalR.connect();

    // Listen for realtime events and refresh providers
    _signalRSubscriptions.add(
      signalR.onRoomStatusChanged.listen((_) {
        ref.read(roomsProvider.notifier).loadRooms();
      }),
    );
    _signalRSubscriptions.add(
      signalR.onOrderStatusChanged.listen((_) {
        ref.read(ordersProvider.notifier).loadOrders();
      }),
    );
    _signalRSubscriptions.add(
      signalR.onServiceRequestCreated.listen((_) {
        ref.read(serviceRequestsProvider.notifier).loadRequests();
      }),
    );
  }

  void _setupFCMHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.data}');
      _handleFCMMessage(message);
    });

    // Handle messages that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.data}');
      _handleFCMMessage(message);
    });

    // Check for initial message (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('FCM initial message: ${message.data}');
        _handleFCMMessage(message);
      }
    });
  }

  void _handleFCMMessage(RemoteMessage message) {
    final type = message.data['type'];

    switch (type) {
      case 'service_request':
        // Refresh service requests list
        ref.read(serviceRequestsProvider.notifier).loadRequests();
        break;
      case 'new_order':
        // Refresh orders list
        ref.read(ordersProvider.notifier).loadOrders();
        break;
      case 'new_reservation':
        // Refresh rooms list
        ref.read(roomsProvider.notifier).loadRooms();
        break;
      default:
        debugPrint('Unknown FCM message type: $type');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Chillax Admin',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeState.materialThemeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B), // zinc-900 (black)
        ),
        useMaterial3: true,
        fontFamily: getFontFamily(locale),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B), // zinc-900 (black)
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: getFontFamily(locale),
      ),
      routerConfig: router,
      builder: (context, child) {
        return FTheme(
          data: themeState.getForuiTheme(context, locale: locale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
