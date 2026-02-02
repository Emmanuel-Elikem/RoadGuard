import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../shared/widgets/floating_nav_bar.dart';

/// Shell screen that wraps bottom navigation destinations.
///
/// Uses a Stack to make the FloatingNavBar truly float over content,
/// allowing the content to extend behind the nav bar (like ChatGPT's input bar).
class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove any default background from Scaffold
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content - extends all the way to bottom
          child,
          // Floating nav bar positioned at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: FloatingNavBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
