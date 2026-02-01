import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';

/// Settings/Profile screen with theme-aware styling.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.floatingNavBarSafeArea,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Settings', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'App preferences & account',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // === ACCOUNT SECTION ===
              _SectionHeader(title: 'Account'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.user,
                title: 'Profile',
                subtitle: 'Guest user',
                onTap: () {},
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === APPEARANCE SECTION ===
              _SectionHeader(title: 'Appearance'),
              const SizedBox(height: AppDimensions.spacingSm),

              // Theme selector with modern pill design
              _ThemeSelector(
                currentTheme: currentTheme,
                onThemeChanged: (mode) {
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                },
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === NOTIFICATIONS SECTION ===
              _SectionHeader(title: 'Notifications'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.bell,
                title: 'Push Notifications',
                subtitle: 'Speed alerts & updates',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (value) {},
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                ),
                onTap: () {},
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.volume2,
                title: 'Sound Alerts',
                subtitle: 'Audio warnings',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (value) {},
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                ),
                onTap: () {},
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === PRIVACY SECTION ===
              _SectionHeader(title: 'Privacy & Data'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.shield,
                title: 'Privacy',
                subtitle: 'Data & permissions',
                onTap: () {},
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.helpCircle,
                title: 'Help & Support',
                subtitle: 'FAQ & contact',
                onTap: () {},
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Version info
              Center(
                child: Text(
                  'RoadGuard v0.1.0 • Week 2',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header with subtle styling.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.spacingXs),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Modern theme selector with animated sliding indicator.
class _ThemeSelector extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;

  const _ThemeSelector({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.palette,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text('Theme', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),

          // Animated segmented control with sliding indicator
          _AnimatedThemeToggle(
            currentTheme: currentTheme,
            onThemeChanged: onThemeChanged,
          ),

          const SizedBox(height: AppDimensions.spacingSm),

          // Helper text
          Text(
            currentTheme == AppThemeMode.system
                ? 'Follows your device settings'
                : currentTheme == AppThemeMode.light
                    ? 'Always use light theme'
                    : 'Always use dark theme',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated theme toggle with sliding highlight indicator.
class _AnimatedThemeToggle extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;

  const _AnimatedThemeToggle({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  int get _selectedIndex => switch (currentTheme) {
        AppThemeMode.system => 0,
        AppThemeMode.light => 1,
        AppThemeMode.dark => 2,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 3; // 8 = padding
        
        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Stack(
            children: [
              // Sliding highlight indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: _selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Options row
              Row(
                children: [
                  _ThemeOptionButton(
                    icon: Icons.brightness_auto,
                    label: 'System',
                    isSelected: currentTheme == AppThemeMode.system,
                    onTap: () => onThemeChanged(AppThemeMode.system),
                  ),
                  _ThemeOptionButton(
                    icon: Icons.light_mode,
                    label: 'Light',
                    isSelected: currentTheme == AppThemeMode.light,
                    onTap: () => onThemeChanged(AppThemeMode.light),
                  ),
                  _ThemeOptionButton(
                    icon: Icons.dark_mode,
                    label: 'Dark',
                    isSelected: currentTheme == AppThemeMode.dark,
                    onTap: () => onThemeChanged(AppThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Theme option button (label only, highlight handled by parent).
class _ThemeOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware settings tile with modern rounded design.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon container with rounded background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  LucideIcons.chevronRight,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
