import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';

/// Breakpoint for tablet layout
const double kTabletBreakpoint = 768;

/// Navigation item model
class NavItem {
  final String route;
  final String label;
  final IconData icon;

  const NavItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

/// Main navigation items (shown in bottom nav on mobile)
const List<NavItem> mainNavItems = [
  NavItem(route: '/dashboard', label: 'Home', icon: Icons.home_outlined),
  NavItem(route: '/orders', label: 'Orders', icon: Icons.receipt_long_outlined),
  NavItem(route: '/rooms', label: 'Rooms', icon: Icons.videogame_asset_outlined),
  NavItem(route: '/service-requests', label: 'Requests', icon: Icons.notifications_outlined),
];

/// Secondary nav items (shown in More menu on mobile, sidebar on tablet)
const List<NavItem> secondaryNavItems = [
  NavItem(route: '/menu', label: 'Menu', icon: Icons.restaurant_menu_outlined),
  NavItem(route: '/loyalty', label: 'Loyalty', icon: Icons.card_giftcard_outlined),
  NavItem(route: '/accounts', label: 'Accounts', icon: Icons.account_balance_wallet_outlined),
  NavItem(route: '/customers', label: 'Customers', icon: Icons.people_outline),
  NavItem(route: '/settings', label: 'Settings', icon: Icons.settings_outlined),
];

/// Admin scaffold - mobile-first with bottom nav, sidebar on tablet
class AdminScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= kTabletBreakpoint;

    if (isTablet) {
      return _TabletLayout(currentRoute: currentRoute, child: child);
    } else {
      return _MobileLayout(currentRoute: currentRoute, child: child);
    }
  }
}

/// Mobile layout with bottom navigation
class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _MobileLayout({required this.child, required this.currentRoute});

  int _getSelectedIndex() {
    for (int i = 0; i < mainNavItems.length; i++) {
      if (currentRoute.startsWith(mainNavItems[i].route)) return i;
    }
    // Check if current route is in secondary items (More is selected)
    for (final item in secondaryNavItems) {
      if (currentRoute.startsWith(item.route)) return mainNavItems.length; // More index
    }
    return 0;
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final authState = ref.read(authServiceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // User info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.name ?? 'Admin',
                          style: theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          authState.email ?? '',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colors.border),
            // Nav items
            ...secondaryNavItems.map((item) {
              final isSelected = currentRoute.startsWith(item.route);
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: isSelected ? theme.colors.primary : theme.colors.foreground,
                ),
                title: Text(
                  item.label,
                  style: theme.typography.base.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? theme.colors.primary : theme.colors.foreground,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(item.route);
                },
              );
            }),
            Divider(height: 1, color: theme.colors.border),
            // Logout
            ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colors.destructive,
              ),
              title: Text(
                'Logout',
                style: theme.typography.base.copyWith(
                  color: theme.colors.destructive,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authServiceProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final authState = ref.watch(authServiceProvider);
    final selectedIndex = _getSelectedIndex();
    final isProfileSelected = selectedIndex == mainNavItems.length;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colors.background,
          border: Border(top: BorderSide(color: theme.colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < mainNavItems.length; i++)
                  _NavBarItem(
                    icon: mainNavItems[i].icon,
                    label: mainNavItems[i].label,
                    isSelected: selectedIndex == i,
                    onTap: () => context.go(mainNavItems[i].route),
                  ),
                // Profile button
                _ProfileNavItem(
                  initial: (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                  isSelected: isProfileSelected,
                  onTap: () => _showProfileMenu(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom nav bar item
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = isSelected ? theme.colors.primary : theme.colors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.typography.xs.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile nav item with avatar
class _ProfileNavItem extends StatelessWidget {
  final String initial;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.initial,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = isSelected ? theme.colors.primary : theme.colors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.mutedForeground.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.colors.primaryForeground : color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Profile',
              style: theme.typography.xs.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tablet layout with sidebar
class _TabletLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _TabletLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final theme = context.theme;
    final allNavItems = [...mainNavItems, ...secondaryNavItems];

    return Row(
      children: [
        // Sidebar
        Container(
          width: 220,
          color: theme.colors.background,
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset('assets/images/logo.png', height: 28),
              ),
              const FDivider(),
              // Nav items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: allNavItems.map((item) {
                    final isSelected = currentRoute.startsWith(item.route);
                    return _SidebarItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () {
                        if (!isSelected) context.go(item.route);
                      },
                    );
                  }).toList(),
                ),
              ),
              // User footer
              const FDivider(),
              _UserFooter(authState: authState, ref: ref),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: theme.colors.border),
        // Content
        Expanded(child: child),
      ],
    );
  }
}

/// Sidebar nav item
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.typography.sm.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? theme.colors.primary
                        : theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// User footer
class _UserFooter extends StatelessWidget {
  final AuthState authState;
  final WidgetRef ref;

  const _UserFooter({required this.authState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (authState.name ?? 'A').substring(0, 1).toUpperCase(),
                style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.name ?? 'Admin',
                  style: theme.typography.sm.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  authState.email ?? '',
                  style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 18, color: theme.colors.mutedForeground),
            onPressed: () async {
              await ref.read(authServiceProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
