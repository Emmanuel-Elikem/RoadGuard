import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';

/// Statistics/Trip history screen with theme-aware styling.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistics', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Your driving history & insights',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const Spacer(),

              // Empty state with modern design
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXl,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.barChart3,
                        size: 48,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text('No trips yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      'Start tracking to see your stats',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
