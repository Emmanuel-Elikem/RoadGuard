/// Permission Service - Handles runtime permissions for location access.
///
/// Provides a clean API for checking and requesting location permissions
/// with proper state tracking and error handling.
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
      LocationPermissionState.unknown => 'Permission Required',
      LocationPermissionState.serviceDisabled => 'Location Disabled',
      LocationPermissionState.denied => 'Permission Denied',
      LocationPermissionState.deniedForever => 'Permission Blocked',
      LocationPermissionState.grantedWhileInUse => 'Permission Granted',
      LocationPermissionState.grantedAlways => 'Full Access Granted',
    };
  }

  /// User-friendly description.
  String get description {
    return switch (this) {
      LocationPermissionState.unknown =>
        'RoadGuard needs location access to track your speed and ensure safe travels.',
      LocationPermissionState.serviceDisabled =>
        'Please enable Location Services in your device settings to use speed tracking.',
      LocationPermissionState.denied =>
        'Location permission is required for speed tracking. Tap to grant access.',
      LocationPermissionState.deniedForever =>
        'Location permission was blocked. Please enable it in Settings > Apps > RoadGuard > Permissions.',
      LocationPermissionState.grantedWhileInUse =>
        'Speed tracking works while the app is open. For background tracking, grant "Always" permission.',
      LocationPermissionState.grantedAlways =>
        'Full location access granted. Speed tracking works in foreground and background.',
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

    // Check current permission status
    final status = await Permission.location.status;
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
    final status = await Permission.location.request();
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
    final status = await Permission.locationAlways.request();
    debugPrint('PermissionService: Background request result = $status');

    // Re-check full state
    return checkLocationPermission();
  }

  /// Open app settings so user can manually enable permissions.
  Future<bool> openAppSettings() async {
    debugPrint('PermissionService: Opening app settings');
    return await openAppSettings();
  }

  /// Open device location settings.
  Future<bool> openLocationSettings() async {
    debugPrint('PermissionService: Opening location settings');
    return await Geolocator.openLocationSettings();
  }

  /// Map permission_handler status to our state enum.
  LocationPermissionState _mapPermissionStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => LocationPermissionState.grantedWhileInUse,
      PermissionStatus.limited => LocationPermissionState.grantedWhileInUse,
      PermissionStatus.denied => LocationPermissionState.denied,
      PermissionStatus.restricted => LocationPermissionState.deniedForever,
      PermissionStatus.permanentlyDenied =>
        LocationPermissionState.deniedForever,
      PermissionStatus.provisional => LocationPermissionState.grantedWhileInUse,
    };
  }
}
