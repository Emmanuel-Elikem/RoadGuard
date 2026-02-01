import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/router/routes.dart';
import '../../core/theme/theme.dart';

/// Navigation item data.
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Floating bottom navigation bar with mercury indicator animation.
/// Fully theme-aware with modern rounded pill design.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  static const _items = [
    NavItem(
      label: 'Home',
      icon: LucideIcons.home,
      activeIcon: LucideIcons.home,
      route: Routes.home,
    ),
    NavItem(
      label: 'Stats',
      icon: LucideIcons.barChart3,
      activeIcon: LucideIcons.barChart3,
      route: Routes.stats,
    ),
    NavItem(
      label: 'Search',
      icon: LucideIcons.search,
      activeIcon: LucideIcons.search,
      route: Routes.search,
    ),
    NavItem(
      label: 'Settings',
      icon: LucideIcons.settings,
      activeIcon: LucideIcons.settings,
      route: Routes.settings,
    ),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].route == location) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentIndex = _getCurrentIndex(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        // Semi-transparent background for floating effect
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (index) {
          return _NavBarItem(
            item: _items[index],
            isSelected: index == currentIndex,
            onTap: () => context.go(_items[index].route),
          );
        }),
      ),
    );
  }
}

/// Theme-aware nav bar item with smooth animations.
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected
              ? AppDimensions.spacingMd
              : AppDimensions.spacingSm,
          vertical: AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: isSelected
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                size: 22,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimensions.spacingSm,
                      ),
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
