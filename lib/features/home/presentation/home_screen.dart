/// Home Screen - Dashboard with real-time speed tracking.
///
/// Features:
/// - Speedometer display with live GPS speed
/// - Permission request flow
/// - Start/stop tracking button
/// - Safety tips ticker
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/permission_service.dart';
import '../../../shared/widgets/speedometer_widget.dart';
import '../../tracking/domain/providers/tracking_providers.dart';

/// Home/Dashboard screen with speed tracking.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background (e.g., after user enables location in Settings),
    // refresh permission state to detect any changes
    if (state == AppLifecycleState.resumed) {
      debugPrint('HomeScreen: App resumed, refreshing permissions');
      ref.read(permissionNotifierProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trackingState = ref.watch(speedTrackingProvider);
    final permissionState = ref.watch(permissionNotifierProvider);

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
            children: [
              // Header
              _Header(
                isTracking: trackingState.state == TrackingState.tracking,
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              // Main content based on permission state
              Expanded(
                child: permissionState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorView(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(permissionNotifierProvider.notifier).refresh(),
                  ),
                  data: (permission) {
                    if (!permission.canTrack) {
                      return _PermissionRequired(permission: permission);
                    }
                    return _TrackingView(trackingState: trackingState);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header with greeting and status.
class _Header extends StatelessWidget {
  final bool isTracking;

  const _Header({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RoadGuard', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppDimensions.spacingXs),
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
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text(
                    isTracking ? 'Tracking Active' : 'Ready to Track',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Placeholder for search (Week 5)
        IconButton(
          onPressed: () {},
          icon: Icon(
            LucideIcons.search,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// View shown when location permission is needed.
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
            // Icon
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

            // Title
            Text(
              permission.title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spacingMd),

            // Description
            Text(
              permission.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spacingXl),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _handlePermissionAction(ref, permission),
                icon: Icon(
                  permission == LocationPermissionState.deniedForever
                      ? LucideIcons.settings
                      : LucideIcons.mapPin,
                ),
                label: Text(
                  permission == LocationPermissionState.deniedForever
                      ? 'Open Settings'
                      : permission == LocationPermissionState.serviceDisabled
                      ? 'Enable Location'
                      : 'Grant Permission',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePermissionAction(
    WidgetRef ref,
    LocationPermissionState permission,
  ) {
    if (permission == LocationPermissionState.deniedForever) {
      PermissionService.instance.openAppSettings();
    } else if (permission == LocationPermissionState.serviceDisabled) {
      PermissionService.instance.openLocationSettings();
    } else {
      ref.read(permissionNotifierProvider.notifier).requestPermission();
    }
  }
}

/// Main tracking view with speedometer.
class _TrackingView extends ConsumerWidget {
  final SpeedTrackingState trackingState;

  const _TrackingView({required this.trackingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTracking = trackingState.state == TrackingState.tracking;

    return Column(
      children: [
        // Speedometer
        Expanded(
          child: Center(
            child: SpeedometerWidget(
              speed: trackingState.speedKmh,
              // TODO: Dynamic speed limits (Week 7)
              speedLimit: AppConstants.defaultSpeedLimit,
              signalQuality: isTracking
                  ? trackingState.signalQuality
                  : GpsSignalQuality.none,
              accuracy: trackingState.accuracy,
              size: AppDimensions.speedometerSize,
            ),
          ),
        ),

        // Safety tip card
        const _SafetyTipCard(),

        const SizedBox(height: AppDimensions.spacingLg),

        // Start/Stop button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed:
                trackingState.state == TrackingState.starting ||
                    trackingState.state == TrackingState.stopping
                ? null
                : () =>
                      ref.read(speedTrackingProvider.notifier).toggleTracking(),
            icon:
                trackingState.state == TrackingState.starting ||
                    trackingState.state == TrackingState.stopping
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
                : Icon(isTracking ? LucideIcons.square : LucideIcons.play),
            label: Text(
              isTracking
                  ? 'Stop Tracking'
                  : trackingState.state == TrackingState.starting
                  ? 'Starting...'
                  : 'Start Tracking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isTracking
                    ? colorScheme.onError
                    : colorScheme.onPrimary,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isTracking
                  ? AppColors.error
                  : colorScheme.primary,
              foregroundColor: isTracking
                  ? colorScheme.onError
                  : colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Safety tip card with rotating tips.
class _SafetyTipCard extends StatelessWidget {
  const _SafetyTipCard();

  // TODO: Rotate through tips, fetch from backend
  static const _tips = [
    'Always wear your seatbelt when traveling.',
    'Observe the speed limit for safer journeys.',
    'Stay alert and report reckless driving.',
    'Take breaks on long trips to stay fresh.',
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
            child: const Icon(
              LucideIcons.lightbulb,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Tip',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tips[DateTime.now().minute % _tips.length],
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view for handling failures.
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
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
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
