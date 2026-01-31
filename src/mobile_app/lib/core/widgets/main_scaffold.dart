import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme_provider.dart';

/// Main scaffold with bottom navigation using Forui
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              label: Text(
                l10n.menu,
                style: context.textStyle(
                  fontWeight: currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.receipt),
              label: Text(
                l10n.orders,
                style: context.textStyle(
                  fontWeight: currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.gamepad2),
              label: Text(
                l10n.rooms,
                style: context.textStyle(
                  fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.user),
              label: Text(
                l10n.profile,
                style: context.textStyle(
                  fontWeight: currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: child,
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
