/// Unit tests for LocationService and SpeedReading.
///
/// Tests edge cases:
/// - Invalid GPS speed values
/// - Reliability checks for accuracy and speed bounds
/// - Speed unit conversions
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/services/location_service.dart';

void main() {
  group('SpeedReading', () {
    group('speed conversions', () {
      test('converts m/s to km/h correctly', () {
        final reading = SpeedReading(
          speedMs: 10.0,
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.speedKmh, closeTo(36.0, 0.1));
      });

      test('converts m/s to mph correctly', () {
        final reading = SpeedReading(
          speedMs: 10.0,
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.speedMph, closeTo(22.37, 0.1));
      });

      test('zero speed returns 0 in all units', () {
        final reading = SpeedReading(
          speedMs: 0,
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.speedKmh, 0);
        expect(reading.speedMph, 0);
      });
    });

    group('isReliable', () {
      test('returns true for good accuracy and normal speed', () {
        final reading = SpeedReading(
          speedMs: 20.0, // ~72 km/h
          latitude: 0,
          longitude: 0,
          accuracy: 10, // 10m accuracy = good
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isTrue);
      });

      test('returns false for poor GPS accuracy (>20m)', () {
        final reading = SpeedReading(
          speedMs: 10.0,
          latitude: 0,
          longitude: 0,
          accuracy: 50, // 50m = poor accuracy
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isFalse);
      });

      test('returns false for negative speed', () {
        final reading = SpeedReading(
          speedMs: -5.0, // Invalid
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isFalse);
      });

      test('returns false for speed > 300 km/h (83.33 m/s)', () {
        final reading = SpeedReading(
          speedMs: 100.0, // ~360 km/h = unreliable GPS spike
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isFalse);
      });

      test('returns true for exactly 300 km/h', () {
        final reading = SpeedReading(
          speedMs: 83.33, // Exactly max reasonable speed
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isTrue);
      });

      test('returns true for boundary accuracy (20m)', () {
        final reading = SpeedReading(
          speedMs: 10.0,
          latitude: 0,
          longitude: 0,
          accuracy: 20, // Exactly at boundary
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.isReliable, isTrue);
      });
    });

    group('factory constructors', () {
      test('zero() creates stationary reading', () {
        final reading = SpeedReading.zero();
        expect(reading.speedMs, 0);
        expect(reading.speedKmh, 0);
        expect(reading.latitude, 0);
        expect(reading.longitude, 0);
      });
    });

    group('toString', () {
      test('formats speed and accuracy correctly', () {
        final reading = SpeedReading(
          speedMs: 10.0,
          latitude: 0,
          longitude: 0,
          accuracy: 5,
          heading: 0,
          altitude: 0,
          timestamp: DateTime.now(),
        );
        expect(reading.toString(), contains('36.0 km/h'));
        expect(reading.toString(), contains('5m'));
      });
    });
  });

  group('kMaxReasonableSpeedMs', () {
    test('equals approximately 300 km/h', () {
      expect(kMaxReasonableSpeedMs * 3.6, closeTo(300, 0.5));
    });
  });

  group('LocationService', () {
    test('instance is singleton', () {
      final instance1 = LocationService.instance;
      final instance2 = LocationService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('isTracking is false initially', () {
      expect(LocationService.instance.isTracking, isFalse);
    });

    test('lastReading is null when not tracking', () {
      expect(LocationService.instance.lastReading, isNull);
    });

    test('speedStream is null when not tracking', () {
      expect(LocationService.instance.speedStream, isNull);
    });
  });
}
