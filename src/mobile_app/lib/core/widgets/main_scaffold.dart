import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold with bottom navigation using Forui
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);

    return FScaffold(
      child: SafeArea(
        bottom: false,
        child: child,
      ),
      footer: SafeArea(
        top: false,
        child: FBottomNavigationBar(
          index: currentIndex,
          onChange: (index) => _onItemTapped(index, context),
          children: [
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.utensils),
              label: const Text('Menu'),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.receipt),
              label: const Text('Orders'),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.gamepad2),
              label: const Text('Rooms'),
            ),
            FBottomNavigationBarItem(
              icon: const Icon(FIcons.user),
              label: const Text('Profile'),
            ),
          ],
        ),
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
