import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Wrapper widget for screens inside the shell (with floating navbar).
///
/// Automatically applies:
/// - SafeArea for system UI
/// - Bottom padding for floating navbar
/// - Consistent horizontal padding
/// - Optional scroll behavior
///
/// Usage:
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ShellScreenWrapper(
///       child: Column(children: [...]),
///     );
///   }
/// }
/// ```
class ShellScreenWrapper extends StatelessWidget {
  /// The content to display.
  final Widget child;

  /// Whether to wrap content in a SingleChildScrollView.
  /// Defaults to false.
  final bool scrollable;

  /// Custom padding. If null, uses default spacingLg horizontal padding.
  final EdgeInsets? padding;

  /// Whether to include SafeArea. Defaults to true.
  final bool useSafeArea;

  /// Whether to add floating navbar bottom padding. Defaults to true.
  final bool addNavbarPadding;

  const ShellScreenWrapper({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding,
    this.useSafeArea = true,
    this.addNavbarPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate padding
    final effectivePadding =
        padding ??
        EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
          addNavbarPadding ? AppDimensions.floatingNavBarSafeArea : 0,
        );

    // Build content based on scrollable flag
    Widget content;
    if (scrollable) {
      content = SingleChildScrollView(padding: effectivePadding, child: child);
    } else {
      content = Padding(padding: effectivePadding, child: child);
    }

    // Wrap with SafeArea if needed
    if (useSafeArea) {
      content = SafeArea(
        bottom: false, // Navbar handles bottom safe area
        child: content,
      );
    }

    return Scaffold(backgroundColor: colorScheme.surface, body: content);
  }
}

/// Extension to easily get navbar-safe bottom padding.
extension NavbarSafeContext on BuildContext {
  /// Returns EdgeInsets with floating navbar safe area at bottom.
  EdgeInsets get navbarSafePadding =>
      const EdgeInsets.only(bottom: AppDimensions.floatingNavBarSafeArea);

  /// Returns the navbar safe area height.
  double get navbarSafeHeight => AppDimensions.floatingNavBarSafeArea;
}
