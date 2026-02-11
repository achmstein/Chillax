import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'app_text.dart';

/// Tracks the current route for tab-aware refreshing
class CurrentRouteNotifier extends Notifier<String> {
  @override
  String build() => '/menu';

  void setRoute(String route) {
    state = route;
  }
}

final currentRouteProvider = NotifierProvider<CurrentRouteNotifier, String>(
  CurrentRouteNotifier.new,
);

/// Main scaffold with bottom navigation using Forui
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    Future.microtask(() {
      if (mounted) {
        ref.read(currentRouteProvider.notifier).setRoute(location);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final l10n = AppLocalizations.of(context)!;

    return FScaffold(
      footer: SafeArea(
        top: false,
        child: FBottomNavigationBar(
          index: currentIndex,
          onChange: (index) => _onItemTapped(index, context),
          children: [
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.utensils),
              label: AppText(
                l10n.menu,
                style: TextStyle(
                  fontWeight: currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.receipt),
              label: AppText(
                l10n.orders,
                style: TextStyle(
                  fontWeight: currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.gamepad2),
              label: AppText(
                l10n.rooms,
                style: TextStyle(
                  fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.user),
              label: AppText(
                l10n.profile,
                style: TextStyle(
                  fontWeight: currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: widget.child,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/menu')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/rooms')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/menu');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/rooms');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
