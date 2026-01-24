import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../widgets/admin_scaffold.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/service_requests/screens/service_requests_screen.dart';
import '../../features/rooms/screens/rooms_screen.dart';
import '../../features/menu/screens/menu_list_screen.dart';
import '../../features/menu/screens/categories_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/loyalty/screens/loyalty_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/auth/screens/login_screen.dart';

/// Splash screen shown while checking authentication
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shell route key for preserving state
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isInitializing = authState.isInitializing;
      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final currentLocation = state.matchedLocation;

      final isOnSplash = currentLocation == '/splash';
      final isLoginRoute = currentLocation == '/login';

      // While initializing, stay on or go to splash
      if (isInitializing) {
        return isOnSplash ? null : '/splash';
      }

      // After initialization, redirect from splash based on auth status
      if (isOnSplash) {
        return (isAuthenticated && isAdmin) ? '/dashboard' : '/login';
      }

      // Not authenticated -> login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Authenticated but not admin -> login with error
      if (isAuthenticated && !isAdmin && !isLoginRoute) {
        return '/login?error=not_admin';
      }

      // Authenticated and on login -> dashboard
      if (isAuthenticated && isAdmin && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Splash route
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login route (outside shell)
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final error = state.uri.queryParameters['error'];
          return LoginScreen(error: error);
        },
      ),

      // Shell route with sidebar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdminScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrdersScreen(),
            ),
          ),
          GoRoute(
            path: '/service-requests',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ServiceRequestsScreen(),
            ),
          ),
          GoRoute(
            path: '/rooms',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RoomsScreen(),
            ),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MenuListScreen(),
            ),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomersScreen(),
            ),
          ),
          GoRoute(
            path: '/loyalty',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LoyaltyScreen(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
