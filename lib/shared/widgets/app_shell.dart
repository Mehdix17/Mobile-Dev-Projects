import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.folder_outlined, selectedIcon: Icons.folder, label: 'Decks'),
    (
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      label: 'Marketplace'
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings'
    ),
  ];

  static const _routes = [
    RouteNames.home,
    RouteNames.decks,
    RouteNames.marketplace,
    RouteNames.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isHome = location == RouteNames.home;

    return PopScope(
      canPop: isHome, // Only allow pop (exit) when on home screen
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isHome) {
          // Back gesture on non-home screen -> go to home
          context.go(RouteNames.home);
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          destinations: _destinations
              .map(
                (dest) => NavigationDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.selectedIcon),
                  label: dest.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) {
        return i;
      }
    }

    return _currentIndex;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }
}
