/// Home Screen - Dashboard with compact speedometer and trip info.
///
/// Compact speedometer top-left, trip stats, quick actions.
/// Speed warning toast when limit exceeded.
/// Wired to TripController for start/stop trip recording.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/services/permission_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/gps_status_banner.dart';
import '../../../shared/widgets/speedometer_widget.dart';
import '../../tracking/domain/providers/tracking_providers.dart';
import '../../trip/application/trip_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final trackingState = ref.watch(speedTrackingProvider);
    final permissionState = ref.watch(permissionNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: permissionState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.read(permissionNotifierProvider.notifier).refresh(),
          ),
          data: (permission) {
            if (!permission.canTrack) {
              return _PermissionRequired(permission: permission);
            }
            return _DashboardContent(trackingState: trackingState);
          },
        ),
      ),
    );
  }
}

/// Main dashboard with compact speedometer and content.
class _DashboardContent extends ConsumerStatefulWidget {
  final SpeedTrackingState trackingState;

  const _DashboardContent({required this.trackingState});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  bool _warningShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ts = widget.trackingState;
    final isTracking = ts.state == TrackingState.tracking;
    final tripState = ref.watch(tripControllerProvider);
    final speedLimit = StorageService.instance.speedLimitThreshold;

    // Show speed warning toast when limit exceeded
    if (isTracking && ts.speedKmh > speedLimit) {
      if (!_warningShown) {
        _warningShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Clear any existing snackbar first to prevent stacking
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Overspeeding! Slow down',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          );
        });
      }
    } else {
      _warningShown = false;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.floatingNavBarSafeArea,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === TOP ROW: Compact speedometer + greeting ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpeedometerWidget(
                speed: ts.speedKmh,
                speedLimit: speedLimit.toDouble(),
                hasSignal: ts.hasSignal || !isTracking,
                size: 120,
              ),
              const SizedBox(width: AppDimensions.spacingMd),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('RoadGuard',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTracking
                                ? AppColors.success
                                : colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTracking ? 'Monitoring speed' : 'Ready to go',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (isTracking) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.error),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                onPressed: () => context.go(Routes.search),
                icon: Icon(LucideIcons.search,
                    color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingLg),

          // === GPS STATUS BANNER ===
          GpsStatusBanner(
            quality: ts.gpsSignalQuality,
            isTracking: isTracking,
          ),

          // === LIVE TRIP STATS (shown when tracking) ===
          if (isTracking && tripState == TripState.recording)
            _LiveTripStats(speedLimit: speedLimit)
          else ...[
            _QuickStatsRow(),
            const SizedBox(height: AppDimensions.spacingMd),
            _QuickActions(),
          ],

          const Spacer(),
          const _SafetyTipCard(),
          const SizedBox(height: AppDimensions.spacingMd),
          _TrackingButton(trackingState: ts),
        ],
      ),
    );
  }
}

/// Live trip statistics during active tracking.
class _LiveTripStats extends ConsumerWidget {
  final int speedLimit;
  const _LiveTripStats({required this.speedLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = ref.read(tripControllerProvider.notifier);
    final duration = controller.currentDuration;
    final distance = controller.currentDistance;
    final maxSpeed = controller.currentMaxSpeed;

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              _StatCard(
                icon: LucideIcons.timer,
                label: 'TIME',
                value:
                    '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              _StatCard(
                icon: LucideIcons.navigation,
                label: 'DISTANCE',
                value: '${distance.toStringAsFixed(2)} km',
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            children: [
              _StatCard(
                icon: LucideIcons.zap,
                label: 'FASTEST',
                value: '${maxSpeed.toStringAsFixed(0)} km/h',
                color: maxSpeed > speedLimit ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              _StatCard(
                icon: LucideIcons.gauge,
                label: 'SPEED LIMIT',
                value: '$speedLimit km/h',
                color: colorScheme.tertiary,
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trips = StorageService.instance.tripsBox.values.toList();
    final totalTrips = trips.length;
    final totalDistance =
        trips.fold<double>(0, (sum, t) => sum + t.distance);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(children: [
              Text('$totalTrips',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('Trips',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6))),
            ]),
          ),
          Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withValues(alpha: 0.2)),
          Expanded(
            child: Column(children: [
              Text(totalDistance.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('km travelled',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6))),
            ]),
          ),
          Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withValues(alpha: 0.2)),
          Expanded(
            child: Column(children: [
              Text('${StorageService.instance.speedLimitThreshold}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary)),
              Text('km/h max',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.6))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ActionButton(
          icon: LucideIcons.search,
          label: 'Look Up\nDriver',
          onTap: () => context.go(Routes.search),
          color: colorScheme.primary,
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _ActionButton(
          icon: LucideIcons.barChart3,
          label: 'Your\nTrips',
          onTap: () => context.go(Routes.stats),
          color: colorScheme.secondary,
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        _ActionButton(
          icon: LucideIcons.settings,
          label: 'Speed\nLimit',
          onTap: () => context.go(Routes.settings),
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.8)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingButton extends ConsumerWidget {
  final SpeedTrackingState trackingState;
  const _TrackingButton({required this.trackingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTracking = trackingState.state == TrackingState.tracking;
    final isLoading = trackingState.state == TrackingState.starting ||
        trackingState.state == TrackingState.stopping;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed:
            isLoading ? null : () => _handleToggle(context, ref, isTracking),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isTracking
                      ? colorScheme.onError
                      : colorScheme.onPrimary,
                ),
              )
            : Icon(isTracking ? LucideIcons.square : LucideIcons.play,
                color:
                    isTracking ? colorScheme.onError : colorScheme.onPrimary),
        label: Text(
          isTracking ? 'Stop' : 'Start',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isTracking ? colorScheme.onError : colorScheme.onPrimary,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
              isTracking ? AppColors.error : colorScheme.primary,
          foregroundColor:
              isTracking ? colorScheme.onError : colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }

  Future<void> _handleToggle(
      BuildContext context, WidgetRef ref, bool isTracking) async {
    if (isTracking) {
      await ref.read(speedTrackingProvider.notifier).toggleTracking();
      await ref.read(tripControllerProvider.notifier).stopTrip();
      final trip = ref.read(tripControllerProvider.notifier).currentTrip;
      if (trip != null && context.mounted) {
        context.push(Routes.tripSummary, extra: trip);
      }
    } else {
      await ref.read(speedTrackingProvider.notifier).toggleTracking();
      ref.read(tripControllerProvider.notifier).startTrip();
    }
  }
}

class _SafetyTipCard extends StatelessWidget {
  const _SafetyTipCard();

  static const _tips = [
    'Always wear your seatbelt when traveling.',
    'Observe the speed limit for safer journeys.',
    'Stay alert and report reckless driving.',
    'Take breaks on long trips to stay fresh.',
    'Avoid distractions while on the road.',
    'Check vehicle condition before long trips.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Icon(LucideIcons.lightbulb,
                color: AppColors.info, size: 20),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety Tip',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_tips[DateTime.now().minute % _tips.length],
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRequired extends ConsumerWidget {
  final LocationPermissionState permission;
  const _PermissionRequired({required this.permission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                permission == LocationPermissionState.serviceDisabled
                    ? LucideIcons.mapPinOff
                    : LucideIcons.mapPin,
                size: 56,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            Text(permission.title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(permission.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spacingXl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  if (permission ==
                      LocationPermissionState.deniedForever) {
                    PermissionService.instance.openAppSettings();
                  } else if (permission ==
                      LocationPermissionState.serviceDisabled) {
                    PermissionService.instance.openLocationSettings();
                  } else {
                    ref
                        .read(permissionNotifierProvider.notifier)
                        .requestPermission();
                  }
                },
                icon: Icon(
                    permission ==
                            LocationPermissionState.deniedForever
                        ? LucideIcons.settings
                        : LucideIcons.mapPin,
                    color: colorScheme.onPrimary),
                label: Text(
                  permission ==
                          LocationPermissionState.deniedForever
                      ? 'Open Settings'
                      : permission ==
                              LocationPermissionState.serviceDisabled
                          ? 'Turn on location'
                          : 'Allow location access',
                  style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 64, color: colorScheme.error),
          const SizedBox(height: AppDimensions.spacingMd),
          Text('Something went wrong', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(message,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.spacingLg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
