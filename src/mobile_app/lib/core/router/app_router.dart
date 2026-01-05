import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../../features/menu/screens/menu_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/rooms/screens/rooms_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../widgets/main_scaffold.dart';

/// App router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/menu',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // Redirect to login if not authenticated
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Redirect to menu if authenticated and on login page
      if (isAuthenticated && isLoggingIn) {
        return '/menu';
      }

      return null;
    },
    routes: [
      // Login route
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MenuScreen(),
            ),
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrdersScreen(),
            ),
          ),
          GoRoute(
            path: '/rooms',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RoomsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
