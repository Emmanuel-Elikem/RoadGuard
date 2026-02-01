import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';

/// Home/Dashboard screen with theme-aware styling.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.floatingNavBarSafeArea,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text('Hello, Driver', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Ready to hit the road?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Speed tracking card placeholder
              Expanded(
                child: _PlaceholderCard(
                  icon: LucideIcons.gauge,
                  title: 'Speed Tracking',
                  subtitle: 'Coming in Week 3',
                  accentColor: colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // Quick actions row
              Row(
                children: [
                  Expanded(
                    child: _PlaceholderCard(
                      icon: LucideIcons.star,
                      title: 'Rate Driver',
                      subtitle: 'Week 5',
                      accentColor: colorScheme.tertiary,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _PlaceholderCard(
                      icon: LucideIcons.map,
                      title: 'Trip Map',
                      subtitle: 'Week 7',
                      accentColor: colorScheme.secondary,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware placeholder card with modern rounded design.
class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool compact;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(
        compact ? AppDimensions.spacingMd : AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 56 : 88,
            height: compact ? 56 : 88,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Icon(icon, size: compact ? 28 : 44, color: accentColor),
          ),
          SizedBox(
            height: compact ? AppDimensions.spacingSm : AppDimensions.spacingMd,
          ),
          Text(
            title,
            style: compact
                ? theme.textTheme.titleSmall
                : theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
