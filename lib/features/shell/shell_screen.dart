import 'package:flutter/material.dart';

import '../../shared/widgets/floating_nav_bar.dart';

/// Shell screen that wraps bottom navigation destinations.
///
/// This provides the persistent FloatingNavBar while allowing
/// child screens to change via GoRouter's ShellRoute.
class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const FloatingNavBar());
  }
}
