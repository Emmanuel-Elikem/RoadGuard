import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/services/map_tile_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/domain/providers/auth_providers.dart';

/// Settings/Profile screen - fully functional.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _speedLimit;
  bool _speedAlerts = true;
  bool _backgroundTracking = true;

  @override
  void initState() {
    super.initState();
    _speedLimit = StorageService.instance.speedLimitThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final isGuest = ref.watch(isGuestProvider);

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
              Text('Settings', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Your preferences and account',
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
                title: user?.nameOrEmail ?? 'Guest User',
                subtitle: isGuest
                    ? 'Sign in to save your data across devices'
                    : user?.email ?? 'No email',
                trailing: isGuest
                    ? TextButton(
                        onPressed: () => _signInPrompt(context),
                        child: Text(
                          'Sign In',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      )
                    : null,
                onTap: () => _showAccountProfile(context, user, isGuest),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === TRACKING SECTION ===
              _SectionHeader(title: 'Speed monitoring'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SpeedLimitTile(
                currentLimit: _speedLimit,
                onChanged: (value) async {
                  setState(() => _speedLimit = value);
                  await StorageService.instance.setSpeedLimitThreshold(value);
                },
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.bell,
                title: 'Speed Alerts',
                subtitle: 'Get notified when going too fast',
                trailing: Switch.adaptive(
                  value: _speedAlerts,
                  onChanged: (value) {
                    if (!value) {
                      _confirmToggleOff(
                        context,
                        title: 'Disable Speed Alerts?',
                        description:
                            'You will no longer receive warnings when the vehicle '
                            'exceeds your speed limit ($_speedLimit km/h). '
                            'This means you won\'t be notified about dangerous speeds.',
                        onConfirm: () =>
                            setState(() => _speedAlerts = false),
                      );
                    } else {
                      setState(() => _speedAlerts = true);
                    }
                  },
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                ),
                onTap: () {
                  if (_speedAlerts) {
                    _confirmToggleOff(
                      context,
                      title: 'Disable Speed Alerts?',
                      description:
                          'You will no longer receive warnings when the vehicle '
                          'exceeds your speed limit ($_speedLimit km/h). '
                          'This means you won\'t be notified about dangerous speeds.',
                      onConfirm: () =>
                          setState(() => _speedAlerts = false),
                    );
                  } else {
                    setState(() => _speedAlerts = true);
                  }
                },
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.mapPin,
                title: 'Monitor in background',
                subtitle: 'Keep monitoring when you leave the app',
                trailing: Switch.adaptive(
                  value: _backgroundTracking,
                  onChanged: (value) {
                    if (!value) {
                      _confirmToggleOff(
                        context,
                        title: 'Stop background monitoring?',
                        description:
                            'Speed monitoring will pause when you leave the app. '
                            'Your trips will only be '
                            'recorded while the app is on screen.',
                        onConfirm: () =>
                            setState(() => _backgroundTracking = false),
                      );
                    } else {
                      setState(() => _backgroundTracking = true);
                    }
                  },
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                ),
                onTap: () {
                  if (_backgroundTracking) {
                    _confirmToggleOff(
                      context,
                      title: 'Stop background monitoring?',
                      description:
                          'Speed monitoring will pause when you leave the app. '
                          'Your trips will only be '
                          'recorded while the app is on screen.',
                      onConfirm: () =>
                          setState(() => _backgroundTracking = false),
                    );
                  } else {
                    setState(() => _backgroundTracking = true);
                  }
                },
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === DATA SECTION ===
              _SectionHeader(title: 'Your data'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.mapPin,
                title: 'Offline maps',
                subtitle: 'Manage downloaded map tiles',
                onTap: () => _showOfflineMapDialog(context),
              ),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.trash2,
                title: 'Clear Trip History',
                subtitle: 'Delete all saved trips',
                onTap: () => _confirmClearTrips(context),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              // === ABOUT SECTION ===
              _SectionHeader(title: 'About'),
              const SizedBox(height: AppDimensions.spacingSm),

              _SettingsTile(
                icon: LucideIcons.info,
                title: 'About RoadGuard',
                subtitle: 'v0.1.0 \u2022 MVP Beta',
                onTap: () => _showAbout(context),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Sign out button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: Icon(LucideIcons.logOut, color: colorScheme.error),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              Center(
                child: Text(
                  'RoadGuard v0.1.0 \u2022 Made in Ghana \u{1F1EC}\u{1F1ED}',
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

  // === DIALOGS ===

  void _showAccountProfile(BuildContext context, dynamic user, bool isGuest) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.spacingLg)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingXl + bottomPadding + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: (user?.photoUrl != null)
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: (user?.photoUrl == null)
                    ? Text(
                        user?.initials ?? 'G',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              Text(
                user?.nameOrEmail ?? 'Guest User',
                style: theme.textTheme.titleLarge,
              ),
              if (!isGuest && user?.email != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: AppDimensions.spacingXs),
                  child: Text(
                    user!.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),

              const SizedBox(height: AppDimensions.spacingXs),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  isGuest ? 'Guest Account' : 'Signed In',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isGuest ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLg),

              // Statistics
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileStat(
                      label: 'Trips',
                      value:
                          '${StorageService.instance.currentUserTrips.length}',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color:
                          colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    _ProfileStat(
                      label: 'Distance',
                      value:
                          '${StorageService.instance.currentUserTrips.fold<double>(0, (s, t) => s + t.distance).toStringAsFixed(1)} km',
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color:
                          colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    _ProfileStat(
                      label: 'Joined',
                      value: user?.createdAt != null
                          ? '${user!.createdAt!.month}/${user.createdAt!.year}'
                          : 'N/A',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingMd),

              if (isGuest)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _signInPrompt(context);
                    },
                    icon: Icon(LucideIcons.logIn,
                        color: colorScheme.onPrimary),
                    label: Text(
                      'Sign in to save across devices',
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
                ),

              const SizedBox(height: AppDimensions.spacingSm),
            ],
          ),
        );
      },
    );
  }
  void _confirmToggleOff(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep On'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Turn Off'),
          ),
        ],
      ),
    );
  }

  void _signInPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign In'),
        content: const Text(
            'Sign in to save your trips and ratings across devices.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final router = GoRouter.of(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) router.go(Routes.auth);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Your trips and ratings will be safe when you sign back in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final router = GoRouter.of(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) router.go(Routes.auth);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmClearTrips(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Trip History'),
        content: const Text(
            'This will permanently delete all saved trips. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final colorScheme = Theme.of(context).colorScheme;
              final uid = StorageService.instance.userId;
              if (uid != null) {
                final box = StorageService.instance.tripsBox;
                final userTripKeys = box.keys.where((key) {
                  final trip = box.get(key);
                  return trip != null && trip.userId == uid;
                }).toList();
                for (final key in userTripKeys) {
                  await box.delete(key);
                }
              }
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'All trips have been deleted',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RoadGuard',
      applicationVersion: 'v0.1.0 (MVP Beta)',
      applicationLegalese: '\u00A9 2026 RoadGuard Team\nMade in Ghana',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Your Digital Copilot for road safety. '
          'Monitor speed, rate drivers, and make Ghana\'s roads safer.',
        ),
      ],
    );
  }

  void _showOfflineMapDialog(BuildContext context) {
    final tileService = ref.read(mapTileServiceProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Offline Maps'),
        content: FutureBuilder<({int tileCount, double sizeMB})>(
          future: tileService.isInitialized
              ? tileService.getStoreStats()
              : Future.value((tileCount: 0, sizeMB: 0.0)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final stats = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maps you view are automatically saved for offline use.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _OfflineMapStat(
                  label: 'Cached tiles',
                  value: '${stats?.tileCount ?? 0}',
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                _OfflineMapStat(
                  label: 'Storage used',
                  value: '${(stats?.sizeMB ?? 0).toStringAsFixed(1)} MB',
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await tileService.clearStore();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Map cache cleared')),
                );
              }
            },
            child: Text(
              'Clear cache',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile stat inside account bottom sheet.
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
      ],
    );
  }
}

/// Offline map stat row inside the dialog.
class _OfflineMapStat extends StatelessWidget {
  final String label;
  final String value;
  const _OfflineMapStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Speed limit slider tile.
class _SpeedLimitTile extends StatelessWidget {
  final int currentLimit;
  final ValueChanged<int> onChanged;

  const _SpeedLimitTile(
      {required this.currentLimit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(LucideIcons.gauge,
                    color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed limit alert',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'You\'ll be warned above $currentLimit km/h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$currentLimit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor:
                  colorScheme.onSurface.withValues(alpha: 0.1),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: currentLimit.toDouble(),
              min: 1,
              max: 150,
              divisions: 149,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km/h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
              InkWell(
                onTap: () => onChanged(AppConstants.defaultSpeedLimit.round()),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Reset to default (${AppConstants.defaultSpeedLimit.round()})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Text('150 km/h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

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
            color: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child:
                    Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  LucideIcons.chevronRight,
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
