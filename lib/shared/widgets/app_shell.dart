import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPress;

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

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!isHome) {
          context.go(RouteNames.home);
          return false;
        }

        // Home tab: double-back to exit
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return false;
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          return false;
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
