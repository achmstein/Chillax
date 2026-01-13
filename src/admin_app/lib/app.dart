import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';

class ChillaxAdminApp extends ConsumerStatefulWidget {
  const ChillaxAdminApp({super.key});

  @override
  ConsumerState<ChillaxAdminApp> createState() => _ChillaxAdminAppState();
}

class _ChillaxAdminAppState extends ConsumerState<ChillaxAdminApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize auth service
    await ref.read(authServiceProvider.notifier).initialize();
    // Remove the native splash screen after auth is initialized
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Chillax Admin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B), // zinc-900 (black)
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B), // zinc-900 (black)
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        return FTheme(
          data: AppTheme.light,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
