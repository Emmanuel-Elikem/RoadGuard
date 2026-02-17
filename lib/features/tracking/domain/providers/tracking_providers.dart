/// Speed Tracking Providers - Riverpod state for GPS speed tracking.
///
/// Provides reactive access to:
/// - Location permission state
/// - GPS tracking state
/// - Real-time speed readings
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Signal quality for the GPS Status Banner.
  /// Combines reading accuracy with temporal state (acquiring/lost).
  GpsSignalQuality get gpsSignalQuality {
    if (state == TrackingState.starting && currentReading == null) {
      return GpsSignalQuality.acquiring;
    }
    if (currentReading == null) {
      return GpsSignalQuality.good; // Not tracking, banner hidden anyway
    }
    final age = DateTime.now().difference(currentReading!.timestamp);
    if (age.inSeconds > 10) {
      return GpsSignalQuality.lost;
    }
    return currentReading!.signalQuality;
  }

  SpeedTrackingState copyWith({
    TrackingState? state,
    SpeedReading? currentReading,
    String? errorMessage,
  }) {
    return SpeedTrackingState(
      state: state ?? this.state,
      currentReading: currentReading ?? this.currentReading,
      errorMessage: errorMessage ?? this.errorMessage,
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
      final subscription = _subscription;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
      unawaited(LocationService.instance.stopTracking());
    });

    return const SpeedTrackingState();
  }

  /// Start GPS speed tracking.
  Future<void> startTracking() async {
    if (state.state == TrackingState.tracking) return;

    state = state.copyWith(state: TrackingState.starting);

    // Start tracking first - this creates the stream controller
    final success = await LocationService.instance.startTracking();

    if (!success) {
      state = state.copyWith(
        state: TrackingState.error,
        errorMessage: 'Couldn\'t start speed monitoring. Please check your location settings.',
      );
      return;
    }

    // Get stream reference
    final stream = LocationService.instance.speedStream;
    if (stream == null) {
      debugPrint('SpeedTrackingNotifier: Stream is null after startTracking!');
      state = state.copyWith(
        state: TrackingState.error,
        errorMessage: 'Location service is not responding. Try restarting the app.',
      );
      return;
    }

    debugPrint('SpeedTrackingNotifier: Subscribing to speed stream');

    // Subscribe to speed updates
    _subscription = stream.listen(
      (reading) {
        debugPrint(
          'SpeedTrackingNotifier: Got reading ${reading.speedKmh.toStringAsFixed(1)} km/h',
        );
        state = state.copyWith(
          state: TrackingState.tracking,
          currentReading: reading,
        );
      },
      onError: (error) {
        debugPrint('SpeedTrackingNotifier: Stream error: $error');
        state = state.copyWith(
          state: TrackingState.error,
          errorMessage: error.toString(),
        );
      },
    );

    // Also check for last reading in case we missed the initial emission
    final lastReading = LocationService.instance.lastReading;
    if (lastReading != null) {
      debugPrint(
        'SpeedTrackingNotifier: Using lastReading ${lastReading.speedKmh.toStringAsFixed(1)} km/h',
      );
      state = state.copyWith(
        state: TrackingState.tracking,
        currentReading: lastReading,
      );
    }

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
