import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';

/// Breakpoint for tablet/mobile layout switch
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

/// Main navigation items
const List<NavItem> mainNavItems = [
  NavItem(route: '/dashboard', label: 'Dashboard', icon: Icons.dashboard),
  NavItem(route: '/orders', label: 'Orders', icon: Icons.shopping_cart),
  NavItem(route: '/rooms', label: 'PS Rooms', icon: Icons.videogame_asset),
  NavItem(route: '/menu', label: 'Menu', icon: Icons.restaurant_menu),
  NavItem(route: '/customers', label: 'Customers', icon: Icons.people),
  NavItem(route: '/loyalty', label: 'Loyalty', icon: Icons.card_giftcard),
  NavItem(route: '/settings', label: 'Settings', icon: Icons.settings),
];

/// Admin scaffold with responsive navigation (sidebar on tablet, drawer on mobile)
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
      return _TabletLayout(
        currentRoute: currentRoute,
        child: child,
      );
    } else {
      return _MobileLayout(
        currentRoute: currentRoute,
        child: child,
      );
    }
  }
}

/// Tablet layout with permanent sidebar
class _TabletLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _TabletLayout({
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final theme = context.theme;

    return Row(
      children: [
        // Sidebar
        Container(
          width: 260,
          color: theme.colors.background,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.coffee,
                      size: 28,
                      color: theme.colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chillax Admin',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const FDivider(),
              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: mainNavItems.map((item) {
                    final isSelected = currentRoute.startsWith(item.route);
                    return _NavItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () {
                        if (!isSelected) {
                          context.go(item.route);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              // Footer
              const FDivider(),
              _UserFooter(authState: authState, ref: ref),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Content
        Expanded(child: child),
      ],
    );
  }
}

/// Mobile layout with drawer navigation
class _MobileLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const _MobileLayout({
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authServiceProvider);
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colors.foreground),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.coffee,
              size: 24,
              color: theme.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Chillax Admin',
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: theme.colors.background,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.coffee,
                      size: 28,
                      color: theme.colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chillax Admin',
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const FDivider(),
              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: mainNavItems.map((item) {
                    final isSelected = currentRoute.startsWith(item.route);
                    return _NavItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: isSelected,
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        if (!isSelected) {
                          context.go(item.route);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              // Footer
              const FDivider(),
              _UserFooter(authState: authState, ref: ref),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

/// User footer widget (shared between layouts)
class _UserFooter extends StatelessWidget {
  final AuthState authState;
  final WidgetRef ref;

  const _UserFooter({
    required this.authState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          FAvatar(
            image: const AssetImage('assets/images/avatar.png'),
            fallback: Text(
              (authState.name ?? 'A').substring(0, 1).toUpperCase(),
            ),
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.name ?? 'Admin',
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  authState.email ?? '',
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () async {
              await ref.read(authServiceProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
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
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.mutedForeground,
                ),
                const SizedBox(width: 12),
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

/// Stat card widget for dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? theme.colors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.typography.xl3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
