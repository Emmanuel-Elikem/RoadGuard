/// Location Service - GPS speed tracking with stream-based updates.
///
/// Provides real-time speed data from GPS Doppler velocity.
/// Uses high-accuracy settings for navigation-grade tracking.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Represents a speed reading with metadata.
@immutable
class SpeedReading {
  /// Speed in meters per second (raw from GPS).
  final double speedMs;

  /// Speed in kilometers per hour.
  double get speedKmh => speedMs * 3.6;

  /// Speed in miles per hour.
  double get speedMph => speedMs * 2.237;

  /// Current latitude.
  final double latitude;

  /// Current longitude.
  final double longitude;

  /// GPS accuracy in meters (lower is better).
  final double accuracy;

  /// Heading/bearing in degrees (0 = North, 90 = East).
  final double heading;

  /// Altitude in meters above sea level.
  final double altitude;

  /// Timestamp of this reading.
  final DateTime timestamp;

  /// Whether this reading is considered reliable.
  /// Low accuracy or very high speeds may be unreliable.
  bool get isReliable => accuracy <= 20 && speedMs >= 0 && speedMs <= 83.33;

  const SpeedReading({
    required this.speedMs,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
    required this.altitude,
    required this.timestamp,
  });

  /// Create from Geolocator Position.
  factory SpeedReading.fromPosition(Position position) {
    return SpeedReading(
      // GPS may return -1 for invalid speed, clamp to 0
      speedMs: position.speed < 0 ? 0 : position.speed,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
      altitude: position.altitude,
      timestamp: position.timestamp,
    );
  }

  /// Create a zero/stationary reading.
  factory SpeedReading.zero() {
    return SpeedReading(
      speedMs: 0,
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      heading: 0,
      altitude: 0,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SpeedReading(${speedKmh.toStringAsFixed(1)} km/h, acc: ${accuracy.toStringAsFixed(0)}m)';
}

/// Service for GPS-based location and speed tracking.
///
/// Usage:
/// ```dart
/// final service = LocationService.instance;
///
/// // Start tracking
/// service.startTracking();
///
/// // Listen to speed updates
/// service.speedStream.listen((reading) {
///   print('Speed: ${reading.speedKmh} km/h');
/// });
///
/// // Stop when done
/// service.stopTracking();
/// ```
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  // Stream controller for speed readings
  StreamController<SpeedReading>? _speedController;
  StreamSubscription<Position>? _positionSubscription;

  // Current state
  bool _isTracking = false;
  SpeedReading? _lastReading;

  /// Whether tracking is currently active.
  bool get isTracking => _isTracking;

  /// The most recent speed reading (null if not tracking).
  SpeedReading? get lastReading => _lastReading;

  /// Stream of speed readings. Subscribe to receive updates.
  Stream<SpeedReading>? get speedStream => _speedController?.stream;

  /// GPS settings optimized for vehicle speed tracking.
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0, // Report all movements
  );

  /// Android-specific settings for better control.
  static AndroidSettings get _androidSettings => AndroidSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    intervalDuration: const Duration(seconds: 1), // Request 1 Hz updates
    forceLocationManager: false, // Use FusedLocationProvider
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'RoadGuard Tracking',
      notificationText: 'Monitoring your speed for safety',
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      enableWakeLock: true,
    ),
  );

  /// Start GPS tracking and emit speed readings.
  ///
  /// Returns true if tracking started successfully.
  Future<bool> startTracking() async {
    if (_isTracking) {
      debugPrint('LocationService: Already tracking');
      return true;
    }

    debugPrint('LocationService: Starting GPS tracking');

    // Create new stream controller
    _speedController = StreamController<SpeedReading>.broadcast();

    try {
      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      _lastReading = SpeedReading.fromPosition(initialPosition);
      _speedController?.add(_lastReading!);
      debugPrint('LocationService: Initial reading = $_lastReading');

      // Start position stream
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? _androidSettings
            : _locationSettings,
      ).listen(_handlePosition, onError: _handleError, cancelOnError: false);

      _isTracking = true;
      debugPrint('LocationService: Tracking started');
      return true;
    } catch (e) {
      debugPrint('LocationService: Failed to start tracking: $e');
      await _cleanup();
      return false;
    }
  }

  /// Stop GPS tracking.
  Future<void> stopTracking() async {
    if (!_isTracking) {
      debugPrint('LocationService: Not tracking');
      return;
    }

    debugPrint('LocationService: Stopping tracking');
    await _cleanup();
    debugPrint('LocationService: Tracking stopped');
  }

  /// Get a single current position (one-shot, not streaming).
  Future<SpeedReading?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      return SpeedReading.fromPosition(position);
    } catch (e) {
      debugPrint('LocationService: Failed to get position: $e');
      return null;
    }
  }

  /// Calculate distance between two readings in meters.
  static double distanceBetween(SpeedReading a, SpeedReading b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  // Handle incoming position updates
  void _handlePosition(Position position) {
    final reading = SpeedReading.fromPosition(position);
    _lastReading = reading;
    _speedController?.add(reading);

    if (kDebugMode && reading.speedMs > 0) {
      debugPrint(
        'LocationService: ${reading.speedKmh.toStringAsFixed(1)} km/h',
      );
    }
  }

  // Handle GPS stream errors
  void _handleError(Object error) {
    debugPrint('LocationService: Stream error: $error');
    // Don't stop tracking on transient errors
    // The stream will continue trying
  }

  // Clean up resources
  Future<void> _cleanup() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    await _speedController?.close();
    _speedController = null;

    _isTracking = false;
    _lastReading = null;
  }
}
