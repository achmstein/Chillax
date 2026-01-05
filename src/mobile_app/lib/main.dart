import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ChillaxApp(),
    ),
  );
}

/// Main application widget
class ChillaxApp extends ConsumerStatefulWidget {
  const ChillaxApp({super.key});

  @override
  ConsumerState<ChillaxApp> createState() => _ChillaxAppState();
}

class _ChillaxAppState extends ConsumerState<ChillaxApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth service on app start
    Future.microtask(() {
      ref.read(authServiceProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Chillax',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
