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

  // Show errors visually in release mode (instead of blank white screen)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              details.exception.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  };

  // Load saved locale before app starts
  await initializeLocale();

  // Firebase/FCM disabled for iOS debugging
  // try {
  //   await Firebase.initializeApp();
  //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //   PlatformDispatcher.instance.onError = (error, stack) {
  //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //     return true;
  //   };
  // } catch (_) {}


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
    // DEBUG: Skip ALL initialization — just remove splash immediately
    FlutterNativeSplash.remove();

    // Run auth in background after splash is gone
    try {
      await ref.read(authServiceProvider.notifier).initialize();

      final authState = ref.read(authServiceProvider);
      if (authState.isAuthenticated) {
        _connectSignalR();
        _wasAuthenticated = true;
      }
    } catch (e, stack) {
      debugPrint('App initialization error: $e\n$stack');
    }
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
    final locale = ref.watch(localeProvider);

    // DEBUG: Step 2 — router + auth + locale, NO FTheme/FToaster
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
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // DEBUG overlay — no FTheme/FToaster wrapping
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: IgnorePointer(
                child: Material(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'AUTH: init=${authState.isInitializing}, '
                      'logged=${authState.isAuthenticated}\n'
                      'LOCALE: ${locale.languageCode}\n'
                      'CHILD: ${child?.runtimeType ?? "NULL"}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
