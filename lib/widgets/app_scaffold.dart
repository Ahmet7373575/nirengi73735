import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_navigation.dart';

/// Shell scaffold — body is the navigationShell, bottom bar is AppNavigation.
/// extendBody: true required for Liquid Glass V3 bottom nav.
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Required for V3 Liquid Glass nav
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
    );
  }
}
