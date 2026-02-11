import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../widgets/admin_scaffold.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_history_screen.dart';
import '../../features/service_requests/screens/service_requests_screen.dart';
import '../../features/rooms/screens/rooms_screen.dart';
import '../../features/rooms/screens/room_detail_screen.dart';
import '../../features/menu/screens/menu_list_screen.dart';
import '../../features/menu/screens/menu_item_edit_screen.dart';
import '../../features/menu/screens/categories_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/loyalty/screens/loyalty_screen.dart';
import '../../features/loyalty/screens/loyalty_account_detail_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/accounts/screens/account_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/update_name_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/auth/screens/login_screen.dart';

/// Splash screen shown while checking authentication
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

/// Auth change notifier for GoRouter refreshListenable.
/// This avoids recreating the entire GoRouter on auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authServiceProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authServiceProvider);
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
        return (isAuthenticated && isAdmin) ? '/orders' : '/login';
      }

      // Not authenticated -> login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Authenticated but not admin -> login with error
      if (isAuthenticated && !isAdmin && !isLoginRoute) {
        return '/login?error=not_admin';
      }

      // Authenticated and on login -> orders
      if (isAuthenticated && isAdmin && isLoginRoute) {
        return '/orders';
      }

      // Redirect old /settings route to /profile
      if (currentLocation == '/settings') {
        return '/profile';
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
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrdersScreen(),
            ),
            routes: [
              GoRoute(
                path: 'history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: OrderHistoryScreen(),
                ),
              ),
            ],
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
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) {
                  final roomId = int.parse(state.pathParameters['roomId']!);
                  return RoomDetailScreen(roomId: roomId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MenuListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'items/new',
                builder: (context, state) => const MenuItemEditScreen(),
              ),
              GoRoute(
                path: 'items/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return MenuItemEditScreen(itemId: id);
                },
              ),
            ],
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
            routes: [
              GoRoute(
                path: ':customerId',
                builder: (context, state) {
                  final customerId = state.pathParameters['customerId']!;
                  return CustomerDetailScreen(customerId: customerId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/loyalty',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LoyaltyScreen(),
            ),
            routes: [
              GoRoute(
                path: 'account/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  final accountJson = state.extra as Map<String, dynamic>?;
                  return LoyaltyAccountDetailPageWrapper(
                    userId: userId,
                    accountJson: accountJson,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':customerId',
                builder: (context, state) {
                  final customerId = state.pathParameters['customerId']!;
                  return AccountDetailScreen(customerId: customerId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
            routes: [
              GoRoute(
                path: 'update-name',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: UpdateNameScreen(),
                ),
              ),
              GoRoute(
                path: 'change-password',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ChangePasswordScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
