import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_guard/features/trip/domain/models/route_point.dart';

void main() {
  group('RoutePoint', () {
    test('stores latitude, longitude, and speed', () {
      const point = RoutePoint(
        latitude: 5.6037,
        longitude: -0.1870,
        speedMs: 13.89,
      );

      expect(point.latitude, 5.6037);
      expect(point.longitude, -0.1870);
      expect(point.speedMs, 13.89);
    });

    test('converts speed to km/h correctly', () {
      const point = RoutePoint(
        latitude: 0,
        longitude: 0,
        speedMs: 10.0,
      );
      expect(point.speedKmh, closeTo(36.0, 0.001));
    });

    test('produces correct LatLng', () {
      const point = RoutePoint(
        latitude: 5.6037,
        longitude: -0.1870,
        speedMs: 0,
      );
      final latLng = point.latLng;
      expect(latLng.latitude, 5.6037);
      expect(latLng.longitude, -0.1870);
    });

    test('toList produces [lat, lng, speed]', () {
      const point = RoutePoint(
        latitude: 5.6037,
        longitude: -0.1870,
        speedMs: 13.89,
      );
      expect(point.toList(), [5.6037, -0.1870, 13.89]);
    });

    test('fromList reconstructs a RoutePoint', () {
      final point = RoutePoint.fromList([5.6037, -0.1870, 13.89]);
      expect(point.latitude, 5.6037);
      expect(point.longitude, -0.1870);
      expect(point.speedMs, 13.89);
    });

    test('fromList asserts on wrong length', () {
      expect(
        () => RoutePoint.fromList([1.0, 2.0]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toString includes speed in km/h', () {
      const point = RoutePoint(
        latitude: 5.6037,
        longitude: -0.1870,
        speedMs: 10.0,
      );
      final str = point.toString();
      expect(str, contains('36.0'));
      expect(str, contains('5.6037'));
    });
  });

  group('RoutePointListX.encode', () {
    test('encodes empty list', () {
      final encoded = <RoutePoint>[].encode();
      expect(encoded, isEmpty);
    });

    test('encodes single point', () {
      final points = [
        const RoutePoint(latitude: 5.0, longitude: -0.1, speedMs: 10.0),
      ];
      final encoded = points.encode();
      expect(encoded, [5.0, -0.1, 10.0]);
    });

    test('encodes multiple points as flat list', () {
      final points = [
        const RoutePoint(latitude: 5.0, longitude: -0.1, speedMs: 10.0),
        const RoutePoint(latitude: 5.1, longitude: -0.2, speedMs: 15.0),
        const RoutePoint(latitude: 5.2, longitude: -0.3, speedMs: 20.0),
      ];
      final encoded = points.encode();
      expect(encoded, [
        5.0, -0.1, 10.0,
        5.1, -0.2, 15.0,
        5.2, -0.3, 20.0,
      ]);
      expect(encoded.length, 9);
    });

    test('toLatLngList extracts coordinates', () {
      final points = [
        const RoutePoint(latitude: 5.0, longitude: -0.1, speedMs: 10.0),
        const RoutePoint(latitude: 5.1, longitude: -0.2, speedMs: 15.0),
      ];
      final latLngs = points.toLatLngList();
      expect(latLngs, hasLength(2));
      expect(latLngs[0], equals(const LatLng(5.0, -0.1)));
      expect(latLngs[1], equals(const LatLng(5.1, -0.2)));
    });
  });

  group('decodeRoutePoints', () {
    test('decodes empty list', () {
      final points = decodeRoutePoints([]);
      expect(points, isEmpty);
    });

    test('decodes single point', () {
      final points = decodeRoutePoints([5.0, -0.1, 10.0]);
      expect(points, hasLength(1));
      expect(points[0].latitude, 5.0);
      expect(points[0].longitude, -0.1);
      expect(points[0].speedMs, 10.0);
    });

    test('round-trips encode/decode correctly', () {
      final original = [
        const RoutePoint(latitude: 5.6037, longitude: -0.1870, speedMs: 13.89),
        const RoutePoint(latitude: 5.6040, longitude: -0.1865, speedMs: 14.50),
        const RoutePoint(latitude: 5.6045, longitude: -0.1860, speedMs: 12.00),
      ];
      final encoded = original.encode();
      final decoded = decodeRoutePoints(encoded);

      expect(decoded, hasLength(original.length));
      for (int i = 0; i < original.length; i++) {
        expect(decoded[i].latitude, original[i].latitude);
        expect(decoded[i].longitude, original[i].longitude);
        expect(decoded[i].speedMs, original[i].speedMs);
      }
    });

    test('handles trailing incomplete data gracefully', () {
      // If data has 7 values (2 full points + 1 extra), only 2 points decoded
      final points = decodeRoutePoints([
        5.0, -0.1, 10.0,
        5.1, -0.2, 15.0,
        5.2, // incomplete — ignored
      ]);
      expect(points, hasLength(2));
    });
  });
}
