/// Permission Service - Handles runtime permissions for location and camera.
///
/// Provides a clean API for checking and requesting permissions
/// with proper state tracking and error handling.
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Represents the current state of location permissions.
enum LocationPermissionState {
  /// Permission not yet determined (initial state).
  unknown,

  /// Location services are disabled at system level.
  serviceDisabled,

  /// User denied permission (can ask again).
  denied,

  /// User permanently denied permission (must go to settings).
  deniedForever,

  /// Only "while using" permission granted.
  grantedWhileInUse,

  /// Full "always" permission granted (background tracking).
  grantedAlways,
}

/// Represents the current state of camera permissions.
enum CameraPermissionState {
  /// Permission not yet determined.
  unknown,

  /// User denied permission (can ask again).
  denied,

  /// User permanently denied permission (must go to settings).
  deniedForever,

  /// Camera access granted.
  granted,
}

/// Extension for camera permission helpers.
extension CameraPermissionStateX on CameraPermissionState {
  /// Whether camera can be used.
  bool get canUseCamera => this == CameraPermissionState.granted;

  /// User-friendly message for denied state.
  String get message {
    return switch (this) {
      CameraPermissionState.unknown =>
        'Camera access is needed to scan car numbers.',
      CameraPermissionState.denied =>
        'Camera access is needed to scan car numbers. Tap below to allow it.',
      CameraPermissionState.deniedForever =>
        'To scan car numbers: Open Settings, find RoadGuard, and turn on Camera.',
      CameraPermissionState.granted => 'Camera access enabled.',
    };
  }
}

/// Extension for user-friendly messages.
extension LocationPermissionStateX on LocationPermissionState {
  /// Whether tracking can start with current permission.
  bool get canTrack =>
      this == LocationPermissionState.grantedWhileInUse ||
      this == LocationPermissionState.grantedAlways;

  /// Whether background tracking is allowed.
  bool get canTrackInBackground =>
      this == LocationPermissionState.grantedAlways;

  /// User-friendly title for permission state.
  String get title {
    return switch (this) {
      LocationPermissionState.unknown => 'Location access needed',
      LocationPermissionState.serviceDisabled => 'Location is turned off',
      LocationPermissionState.denied => 'Location access declined',
      LocationPermissionState.deniedForever => 'Location access blocked',
      LocationPermissionState.grantedWhileInUse => 'Location access enabled',
      LocationPermissionState.grantedAlways => 'Full location access enabled',
    };
  }

  /// User-friendly description.
  String get description {
    return switch (this) {
      LocationPermissionState.unknown =>
        'RoadGuard needs to know your location to monitor speed and keep you safe.',
      LocationPermissionState.serviceDisabled =>
        'Turn on Location in your device settings so RoadGuard can monitor speed.',
      LocationPermissionState.denied =>
        'RoadGuard needs location access to work. Tap below to allow it.',
      LocationPermissionState.deniedForever =>
        'Location access was blocked. Open your phone\'s Settings, find RoadGuard, and turn on Location.',
      LocationPermissionState.grantedWhileInUse =>
        'Speed monitoring works while the app is open. To monitor in the background, allow location access "Always".',
      LocationPermissionState.grantedAlways =>
        'All set! Speed monitoring works whether the app is open or in the background.',
    };
  }
}

/// Service for managing location permissions.
///
/// Usage:
/// ```dart
/// final state = await PermissionService.instance.checkLocationPermission();
/// if (!state.canTrack) {
///   final newState = await PermissionService.instance.requestLocationPermission();
/// }
/// ```
class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  /// Check current location permission state without requesting.
  Future<LocationPermissionState> checkLocationPermission() async {
    // First check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('PermissionService: Location services disabled');
      return LocationPermissionState.serviceDisabled;
    }

    // Check if "always" permission is granted (background tracking)
    final alwaysStatus = await ph.Permission.locationAlways.status;
    if (alwaysStatus == ph.PermissionStatus.granted) {
      debugPrint('PermissionService: Always permission granted');
      return LocationPermissionState.grantedAlways;
    }

    // Check current permission status (while in use)
    final status = await ph.Permission.location.status;
    debugPrint('PermissionService: Current status = $status');

    return _mapPermissionStatus(status);
  }

  /// Request location permission from user.
  ///
  /// Returns the new permission state after request.
  Future<LocationPermissionState> requestLocationPermission() async {
    // First ensure location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('PermissionService: Requesting user to enable location');
      // Try to open location settings
      await Geolocator.openLocationSettings();
      // Re-check after user returns
      final stillDisabled = !await Geolocator.isLocationServiceEnabled();
      if (stillDisabled) {
        return LocationPermissionState.serviceDisabled;
      }
    }

    // Request permission
    debugPrint('PermissionService: Requesting location permission');
    final status = await ph.Permission.location.request();
    debugPrint('PermissionService: Request result = $status');

    return _mapPermissionStatus(status);
  }

  /// Request "always" (background) location permission.
  ///
  /// Must have "while in use" permission first.
  Future<LocationPermissionState> requestBackgroundPermission() async {
    // Check we have basic permission first
    final currentState = await checkLocationPermission();
    if (currentState != LocationPermissionState.grantedWhileInUse) {
      debugPrint(
        'PermissionService: Cannot request background without while-in-use',
      );
      return currentState;
    }

    // Request "always" permission
    debugPrint('PermissionService: Requesting background location');
    final status = await ph.Permission.locationAlways.request();
    debugPrint('PermissionService: Background request result = $status');

    // Re-check full state
    return checkLocationPermission();
  }

  /// Open app settings so user can manually enable permissions.
  Future<bool> openAppSettings() async {
    debugPrint('PermissionService: Opening app settings');
    return await ph.openAppSettings();
  }

  /// Open device location settings.
  Future<bool> openLocationSettings() async {
    debugPrint('PermissionService: Opening location settings');
    return await Geolocator.openLocationSettings();
  }

  /// Map permission_handler status to our state enum.
  LocationPermissionState _mapPermissionStatus(ph.PermissionStatus status) {
    return switch (status) {
      ph.PermissionStatus.granted => LocationPermissionState.grantedWhileInUse,
      ph.PermissionStatus.limited => LocationPermissionState.grantedWhileInUse,
      ph.PermissionStatus.denied => LocationPermissionState.denied,
      ph.PermissionStatus.restricted => LocationPermissionState.deniedForever,
      ph.PermissionStatus.permanentlyDenied =>
        LocationPermissionState.deniedForever,
      ph.PermissionStatus.provisional =>
        LocationPermissionState.grantedWhileInUse,
    };
  }

  // ==========================================================================
  // Camera Permissions
  // ==========================================================================

  /// Check current camera permission state without requesting.
  Future<CameraPermissionState> checkCameraPermission() async {
    final status = await ph.Permission.camera.status;
    debugPrint('PermissionService: Camera status = $status');
    return _mapCameraStatus(status);
  }

  /// Request camera permission from user.
  Future<CameraPermissionState> requestCameraPermission() async {
    debugPrint('PermissionService: Requesting camera permission');
    final status = await ph.Permission.camera.request();
    debugPrint('PermissionService: Camera request result = $status');
    return _mapCameraStatus(status);
  }

  /// Map permission_handler status to camera state enum.
  CameraPermissionState _mapCameraStatus(ph.PermissionStatus status) {
    return switch (status) {
      ph.PermissionStatus.granted => CameraPermissionState.granted,
      ph.PermissionStatus.limited => CameraPermissionState.granted,
      ph.PermissionStatus.denied => CameraPermissionState.denied,
      ph.PermissionStatus.restricted => CameraPermissionState.deniedForever,
      ph.PermissionStatus.permanentlyDenied =>
        CameraPermissionState.deniedForever,
      ph.PermissionStatus.provisional => CameraPermissionState.granted,
    };
  }
}
