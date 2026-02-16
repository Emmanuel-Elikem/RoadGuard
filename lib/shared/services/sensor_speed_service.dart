import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'location_service.dart';

/// Service that uses phone accelerometer to provide faster speed updates,
/// fused with GPS for accuracy.
///
/// GPS updates every 1-10 seconds, but sensors update 60+ times per second.
/// This service detects acceleration changes instantly and uses GPS to calibrate.
///
/// Note: Currently uses accelerometer only. Gyroscope/orientation could be added
/// in the future for more accurate direction detection (see Issue #5).
class SensorSpeedService {
  SensorSpeedService._();
  static final SensorSpeedService instance = SensorSpeedService._();

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamController<SensorSpeedReading>? _speedController;

  // State for speed calculation
  double _currentSpeedMs = 0.0;
  double _lastGpsSpeedMs = 0.0;
  DateTime _lastGpsTime = DateTime.now();
  DateTime _lastSensorTime = DateTime.now();

  // Kalman filter state for smoothing
  double _estimatedSpeed = 0.0;
  double _estimateError = 10.0; // Initial uncertainty

  // Constants for tuning
  static const double _measurementNoise = 0.5; // Accelerometer noise
  static const double _processNoise = 0.1; // Speed change noise
  static const double _gravityThreshold = 0.5; // Ignore small accelerations
  static const Duration _gpsTimeout = Duration(seconds: 15);

  // Fusion tuning constants (easy to adjust)
  static const double _poorGpsBlendFactor =
      0.3; // 30% GPS, 70% sensor when GPS is poor

  static const Duration _gpsFreshnessThreshold = Duration(seconds: 5);

  bool _isRunning = false;
  bool get isRunning => _isRunning;
  Stream<SensorSpeedReading>? get speedStream => _speedController?.stream;

  /// Start listening to sensor data.
  /// Call this when GPS tracking starts.
  Future<void> start() async {
    if (_isRunning) return;

    // Await existing controller close to prevent race conditions
    await _speedController?.close();
    _speedController = StreamController<SensorSpeedReading>.broadcast();

    // Reset all state including GPS state (fix stale data bug)
    _currentSpeedMs = 0.0;
    _estimatedSpeed = 0.0;
    _lastGpsSpeedMs = 0.0;
    _lastGpsTime = DateTime.fromMillisecondsSinceEpoch(0); // Mark as no GPS yet
    _lastSensorTime = DateTime.now();
    _estimateError = 10.0; // Reset uncertainty
    _isRunning = true;

    // Use UserAccelerometerEvent which removes gravity
    // This gives us linear acceleration (actual movement)
    _accelSubscription =
        userAccelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50), // 20 Hz
        ).listen(
          _handleAcceleration,
          onError: (e) {
            debugPrint('SensorSpeedService: Accelerometer error: $e');
          },
        );

    debugPrint('SensorSpeedService: Started');
  }

  /// Stop listening to sensor data.
  Future<void> stop() async {
    await _accelSubscription?.cancel();
    _accelSubscription = null;
    await _speedController?.close();
    _speedController = null;
    _isRunning = false;
    _currentSpeedMs = 0.0;
    _estimatedSpeed = 0.0;
    debugPrint('SensorSpeedService: Stopped');
  }

  /// Update with GPS reading to calibrate sensor-based speed.
  /// Call this whenever a new GPS position is received.
  void updateWithGps(SpeedReading gpsReading) {
    if (!_isRunning) return;

    _lastGpsSpeedMs = gpsReading.speedMs;
    _lastGpsTime = gpsReading.timestamp;

    // Reset Kalman filter to GPS value if GPS is reliable
    if (gpsReading.isReliable) {
      // Weight GPS heavily when reliable
      _estimatedSpeed = _lastGpsSpeedMs;
      // Higher accuracy value = higher error (accuracy is in meters)
      _estimateError = gpsReading.accuracy / 10.0;
    } else {
      // Blend GPS with current estimate when GPS is poor
      _estimatedSpeed =
          (_estimatedSpeed * (1 - _poorGpsBlendFactor)) +
          (_lastGpsSpeedMs * _poorGpsBlendFactor);
    }

    _emitReading();
  }

  void _handleAcceleration(UserAccelerometerEvent event) {
    final now = DateTime.now();
    final dt = now.difference(_lastSensorTime).inMilliseconds / 1000.0;
    if (dt <= 0) return;

    _lastSensorTime = now;

    // Calculate magnitude of acceleration (ignoring direction for speed)
    // UserAccelerometerEvent already has gravity removed
    final accelMagnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Only update if acceleration is significant (not just noise)
    if (accelMagnitude > _gravityThreshold) {
      // Integrate acceleration to get velocity change
      // This is approximate - real sensor fusion uses more complex math
      final deltaV = accelMagnitude * dt;

      // Determine if accelerating or decelerating based on forward axis
      // For simplicity, use z-axis as rough forward direction
      final isDecelerating = event.z < -_gravityThreshold;

      if (isDecelerating) {
        _currentSpeedMs = max(0, _currentSpeedMs - deltaV);
      } else {
        _currentSpeedMs += deltaV;
      }
    } else {
      // Small acceleration - apply friction/decay
      // ZUPT: If acceleration is very low for a few frames, force decay faster
      if (accelMagnitude < 0.1) {
         _currentSpeedMs *= 0.8; // Aggressive Stop
         if (_currentSpeedMs < 0.5) _currentSpeedMs = 0; // Snap to zero
      } else {
         _currentSpeedMs *= 0.95; // Normal decay
      }
    }

    // Clamp to reasonable values
    _currentSpeedMs = _currentSpeedMs.clamp(0.0, kMaxReasonableSpeedMs);

    // Kalman filter update
    _kalmanUpdate(_currentSpeedMs);

    _emitReading();
  }

  void _kalmanUpdate(double measurement) {
    // Prediction step
    final predictedError = _estimateError + _processNoise;

    // Update step
    final kalmanGain = predictedError / (predictedError + _measurementNoise);
    _estimatedSpeed =
        _estimatedSpeed + kalmanGain * (measurement - _estimatedSpeed);
    _estimateError = (1 - kalmanGain) * predictedError;

    // If GPS is stale, rely more on sensors
    final gpsAge = DateTime.now().difference(_lastGpsTime);
    if (gpsAge > _gpsTimeout) {
      // GPS is stale - sensor estimate is primary
      _estimateError = min(_estimateError, 5.0);
    }
  }

  void _emitReading() {
    if (_speedController == null || _speedController!.isClosed) return;

    final gpsAge = DateTime.now().difference(_lastGpsTime);
    final source = gpsAge < _gpsFreshnessThreshold
        ? SpeedSource.gpsFused
        : SpeedSource.sensorOnly;

    _speedController!.add(
      SensorSpeedReading(
        speedMs: _estimatedSpeed.clamp(0.0, kMaxReasonableSpeedMs),
        speedKmh: (_estimatedSpeed * 3.6).clamp(
          0.0,
          kMaxReasonableSpeedMs * 3.6,
        ),
        source: source,
        confidence:
            1.0 / (1.0 + _estimateError), // Higher error = lower confidence
        timestamp: DateTime.now(),
      ),
    );
  }
}

/// A speed reading from the sensor fusion service.
class SensorSpeedReading {
  final double speedMs;
  final double speedKmh;
  final SpeedSource source;
  final double confidence; // 0.0 to 1.0
  final DateTime timestamp;

  const SensorSpeedReading({
    required this.speedMs,
    required this.speedKmh,
    required this.source,
    required this.confidence,
    required this.timestamp,
  });

  @override
  String toString() =>
      'SensorSpeed(${speedKmh.toStringAsFixed(1)} km/h, $source, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Source of the speed reading.
enum SpeedSource {
  /// Speed is primarily from GPS with sensor smoothing.
  gpsFused,

  /// Speed is primarily from sensors (GPS is stale).
  sensorOnly,
}
