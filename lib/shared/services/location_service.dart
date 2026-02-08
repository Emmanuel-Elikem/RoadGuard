
import 'dart:async';


import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'background_tracking_service.dart';

/// Maximum reasonable vehicle speed in m/s (300 km/h).
const double kMaxReasonableSpeedMs = 83.33;

/// Minimum speed threshold in km/h when GPS accuracy is poor.
const double kPoorGpsSpeedThreshold = 5.0;

/// Minimum speed threshold in km/h when GPS accuracy is good.
const double kGoodGpsSpeedThreshold = 2.0;

/// GPS signal quality based on accuracy.
enum GpsSignalQuality {
  excellent,
  good,
  poor,
  veryPoor,
  none,
}

extension GpsSignalQualityX on GpsSignalQuality {
  String get label => switch (this) {
    GpsSignalQuality.excellent => 'GPS',
    GpsSignalQuality.good => 'GPS',
    GpsSignalQuality.poor => 'POOR GPS',
    GpsSignalQuality.veryPoor => 'WEAK GPS',
    GpsSignalQuality.none => 'NO GPS',
  };
  
  bool get isUsable => this != GpsSignalQuality.none;
}

/// Represents a speed reading with metadata.
@immutable
class SpeedReading {
  final double speedMs;
  double get speedKmh => speedMs * 3.6;
  double get speedMph => speedMs * 2.237;

  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final double altitude;
  final DateTime timestamp;

  bool get isReliable => accuracy > 0 && accuracy <= 20 && speedMs >= 0 && speedMs <= kMaxReasonableSpeedMs;

  GpsSignalQuality get signalQuality {
    if (accuracy <= 0) return GpsSignalQuality.none;
    if (accuracy <= 10) return GpsSignalQuality.excellent;
    if (accuracy <= 20) return GpsSignalQuality.good;
    if (accuracy <= 50) return GpsSignalQuality.poor;
    return GpsSignalQuality.veryPoor;
  }

  bool get hasGpsData => accuracy > 0;

  /// Returns the raw speed in km/h - same as notification shows.
  /// Use [isLikelyNoise] to determine if the speed might be GPS drift.
  double get displaySpeedKmh => speedKmh;

  /// Indicates if the current reading is likely GPS noise (low speed + poor accuracy).
  /// UI can use this to show a subtle indicator but still display the actual speed.
  bool get isLikelyNoise {
    final threshold = accuracy > 30 ? kPoorGpsSpeedThreshold : kGoodGpsSpeedThreshold;
    return speedKmh < threshold && speedKmh > 0;
  }

  const SpeedReading({
    required this.speedMs,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
    required this.altitude,
    required this.timestamp,
  });

  factory SpeedReading.fromPosition(Position position) {
    return SpeedReading(
      speedMs: position.speed < 0 ? 0 : position.speed,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
      altitude: position.altitude,
      timestamp: position.timestamp,
    );
  }

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

/// Service for handling GPS location and speed tracking using a Background Service.
///
/// Wraps the flutter_background_service package and provides a stream of simplified [SpeedReading]s.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  
  final _service = FlutterBackgroundService();

  // Stream controller to bridge Background Service events to our existing UI code
  StreamController<SpeedReading>? _speedController;

  bool _isTracking = false;
  SpeedReading? _lastReading;

  bool get isTracking => _isTracking;
  SpeedReading? get lastReading => _lastReading;
  Stream<SpeedReading>? get speedStream => _speedController?.stream;

  /// Initialize the background service configuration.
  /// Should be called at app startup.
  Future<void> initialize() async {
    await BackgroundTrackingService().initializeService();
    
    // Listen to updates globally to keep state in sync if methods are called from different places
    _service.on('update').listen((data) {
      if (_isTracking && data != null) {
        _handleBackgroundUpdate(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Start persistent background tracking.
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      // 1. Check permissions again just to be safe
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied');
        return false;
      }

      // 2. Initialize stream controller
      // Close existing if any to prevent leaks
      await _speedController?.close();
      _speedController = StreamController<SpeedReading>.broadcast();

      // 3. Start the Background Service
      final isRunning = await _service.isRunning();
      if (!isRunning) {
        final started = await _service.startService();
        if (!started) {
             debugPrint('LocationService: Failed to start background service');
             return false;
        }
      }

      _isTracking = true;
      debugPrint('LocationService: Background Tracking started');
      return true;
    } catch (e) {
      debugPrint('LocationService: Error starting tracking: $e');
      await _cleanup();
      return false;
    }
  }

  void _handleBackgroundUpdate(Map<String, dynamic> data) {
    try {
        // Reconstruct SpeedReading from JSON data
       final reading = SpeedReading(
        speedMs: (data['speed'] as num).toDouble(),
        accuracy: (data['accuracy'] as num).toDouble(),
        altitude: (data['altitude'] as num).toDouble(),
        heading: (data['heading'] as num).toDouble(),
        latitude: (data['lat'] as num).toDouble(),
        longitude: (data['lng'] as num).toDouble(),
        timestamp: DateTime.parse(data['time'] as String),
      );

      _lastReading = reading;
      
      // Emit to UI listeners
      if (_speedController != null && !_speedController!.isClosed) {
        _speedController!.add(reading);
      }
    } catch (e) {
        debugPrint('LocationService: Error parsing background data: $e');
    }
  }

  /// Stop tracking and kill the background service.
  Future<void> stopTracking() async {
     // Don't check _isTracking here, force stop just in case
    _service.invoke('stopService');
    await _cleanup();
    debugPrint('LocationService: Tracking stopped');
  }

  /// Get a single current position using standard Geolocator (non-persistent)
  /// Useful for quick checks without starting the service.
  Future<SpeedReading?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return SpeedReading.fromPosition(position);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cleanup() async {
    await _speedController?.close();
    _speedController = null;
    _isTracking = false;
    _lastReading = null;
  }
}
