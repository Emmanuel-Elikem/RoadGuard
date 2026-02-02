/// Speed Tracking Providers - Riverpod state for GPS speed tracking.
///
/// Provides reactive access to:
/// - Location permission state
/// - GPS tracking state
/// - Real-time speed readings
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/permission_service.dart';

// =============================================================================
// PERMISSION PROVIDERS
// =============================================================================

/// Provider for current location permission state.
/// Auto-refreshes when permission changes.
final locationPermissionProvider = FutureProvider<LocationPermissionState>((
  ref,
) async {
  return await PermissionService.instance.checkLocationPermission();
});

/// Notifier for requesting location permissions.
class PermissionNotifier extends AsyncNotifier<LocationPermissionState> {
  @override
  Future<LocationPermissionState> build() async {
    return await PermissionService.instance.checkLocationPermission();
  }

  /// Request location permission from user.
  Future<void> requestPermission() async {
    state = const AsyncLoading();
    final result = await PermissionService.instance.requestLocationPermission();
    state = AsyncData(result);
  }

  /// Request background (always) location permission.
  Future<void> requestBackgroundPermission() async {
    state = const AsyncLoading();
    final result = await PermissionService.instance
        .requestBackgroundPermission();
    state = AsyncData(result);
  }

  /// Refresh permission state (e.g., after returning from settings).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await PermissionService.instance.checkLocationPermission();
    state = AsyncData(result);
  }
}

/// Provider for permission management.
final permissionNotifierProvider =
    AsyncNotifierProvider<PermissionNotifier, LocationPermissionState>(
      PermissionNotifier.new,
    );

// =============================================================================
// SPEED TRACKING PROVIDERS
// =============================================================================

/// State for speed tracking.
enum TrackingState {
  /// Not tracking, idle.
  idle,

  /// Starting tracking.
  starting,

  /// Actively tracking speed.
  tracking,

  /// Stopping tracking.
  stopping,

  /// Error occurred.
  error,
}

/// Combined tracking state with current reading.
class SpeedTrackingState {
  final TrackingState state;
  final SpeedReading? currentReading;
  final String? errorMessage;

  const SpeedTrackingState({
    this.state = TrackingState.idle,
    this.currentReading,
    this.errorMessage,
  });

  /// Current speed in km/h (0 if no reading).
  double get speedKmh => currentReading?.speedKmh ?? 0;

  /// Whether we have a valid GPS signal.
  bool get hasSignal =>
      currentReading != null && (currentReading?.isReliable ?? false);

  /// GPS accuracy in meters.
  double? get accuracy => currentReading?.accuracy;

  SpeedTrackingState copyWith({
    TrackingState? state,
    SpeedReading? currentReading,
    String? errorMessage,
  }) {
    return SpeedTrackingState(
      state: state ?? this.state,
      currentReading: currentReading ?? this.currentReading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for speed tracking state.
class SpeedTrackingNotifier extends Notifier<SpeedTrackingState> {
  StreamSubscription<SpeedReading>? _subscription;

  @override
  SpeedTrackingState build() {
    // Clean up when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
      LocationService.instance.stopTracking();
    });

    return const SpeedTrackingState();
  }

  /// Start GPS speed tracking.
  Future<void> startTracking() async {
    if (state.state == TrackingState.tracking) return;

    state = state.copyWith(state: TrackingState.starting);

    final success = await LocationService.instance.startTracking();

    if (!success) {
      state = state.copyWith(
        state: TrackingState.error,
        errorMessage: 'Failed to start GPS tracking',
      );
      return;
    }

    // Subscribe to speed updates
    _subscription = LocationService.instance.speedStream?.listen(
      (reading) {
        state = state.copyWith(
          state: TrackingState.tracking,
          currentReading: reading,
        );
      },
      onError: (error) {
        state = state.copyWith(
          state: TrackingState.error,
          errorMessage: error.toString(),
        );
      },
    );

    state = state.copyWith(state: TrackingState.tracking);
  }

  /// Stop GPS speed tracking.
  Future<void> stopTracking() async {
    if (state.state != TrackingState.tracking) return;

    state = state.copyWith(state: TrackingState.stopping);

    await _subscription?.cancel();
    _subscription = null;

    await LocationService.instance.stopTracking();

    state = const SpeedTrackingState(state: TrackingState.idle);
  }

  /// Toggle tracking on/off.
  Future<void> toggleTracking() async {
    if (state.state == TrackingState.tracking) {
      await stopTracking();
    } else {
      await startTracking();
    }
  }
}

/// Provider for speed tracking.
final speedTrackingProvider =
    NotifierProvider<SpeedTrackingNotifier, SpeedTrackingState>(
      SpeedTrackingNotifier.new,
    );

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Simple provider for current speed in km/h.
final currentSpeedProvider = Provider<double>((ref) {
  final tracking = ref.watch(speedTrackingProvider);
  return tracking.speedKmh;
});

/// Simple provider for tracking active state.
final isTrackingProvider = Provider<bool>((ref) {
  final tracking = ref.watch(speedTrackingProvider);
  return tracking.state == TrackingState.tracking;
});

/// Provider for GPS signal status.
final hasGpsSignalProvider = Provider<bool>((ref) {
  final tracking = ref.watch(speedTrackingProvider);
  return tracking.hasSignal;
});
