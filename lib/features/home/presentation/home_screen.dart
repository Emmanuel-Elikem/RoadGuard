import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';

/// Home/Dashboard screen placeholder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, Driver',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Ready to hit the road?',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Speed tracking card placeholder
              Expanded(
                child: _PlaceholderCard(
                  icon: LucideIcons.gauge,
                  title: 'Speed Tracking',
                  subtitle: 'Coming in Week 3',
                  color: AppColors.primary,
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
                      color: AppColors.warning,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: _PlaceholderCard(
                      icon: LucideIcons.map,
                      title: 'Trip Map',
                      subtitle: 'Week 7',
                      color: AppColors.secondary,
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

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool compact;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact ? AppDimensions.spacingMd : AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 48 : 80,
            height: compact ? 48 : 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, size: compact ? 24 : 40, color: color),
          ),
          SizedBox(
            height: compact ? AppDimensions.spacingSm : AppDimensions.spacingMd,
          ),
          Text(
            title,
            style: compact
                ? AppTypography.titleSmall
                : AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
