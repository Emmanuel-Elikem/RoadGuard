import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_guard/features/trip/domain/models/route_point.dart';
import 'package:road_guard/shared/utils/map_geometry.dart';

/// Tests for route visualization logic used in TripRouteMap.
///
/// Tests the shared bounds and zoom computation from map_geometry.dart.
void main() {
  group('Route bounds computation', () {
    test('single point returns identical SW and NE', () {
      final points = [const LatLng(5.6037, -0.1870)];
      final bounds = computeRouteBounds(points);
      expect(bounds.$1, equals(bounds.$2));
    });

    test('two-point route computes correct SW/NE', () {
      final points = [
        const LatLng(5.60, -0.19),
        const LatLng(5.62, -0.17),
      ];
      final bounds = computeRouteBounds(points);
      expect(bounds.$1.latitude, 5.60);
      expect(bounds.$1.longitude, -0.19);
      expect(bounds.$2.latitude, 5.62);
      expect(bounds.$2.longitude, -0.17);
    });

    test('multi-point route finds extremes', () {
      final points = [
        const LatLng(5.60, -0.19),
        const LatLng(5.58, -0.20),
        const LatLng(5.64, -0.15),
        const LatLng(5.61, -0.18),
      ];
      final bounds = computeRouteBounds(points);
      expect(bounds.$1.latitude, 5.58);
      expect(bounds.$1.longitude, -0.20);
      expect(bounds.$2.latitude, 5.64);
      expect(bounds.$2.longitude, -0.15);
    });
  });

  group('Route zoom estimation', () {
    test('very small route (< 0.002°) gets zoom 17', () {
      final bounds = (
        const LatLng(5.600, -0.190),
        const LatLng(5.601, -0.189),
      );
      expect(computeRouteZoom(bounds), 17.0);
    });

    test('medium route (0.01-0.02°) gets zoom 14', () {
      final bounds = (
        const LatLng(5.60, -0.19),
        const LatLng(5.61, -0.18),
      );
      expect(computeRouteZoom(bounds), 14.0);
    });

    test('large route (> 0.2°) gets zoom 10', () {
      final bounds = (
        const LatLng(5.50, -0.30),
        const LatLng(5.80, -0.10),
      );
      expect(computeRouteZoom(bounds), 10.0);
    });
  });

  group('RoutePoint toLatLngList integration', () {
    test('decoded route produces valid LatLng list for map', () {
      final encoded = [
        5.600, -0.190, 10.0,
        5.605, -0.185, 12.5,
        5.610, -0.180, 15.0,
      ];
      final points = decodeRoutePoints(encoded);
      final latLngs = points.toLatLngList();

      expect(latLngs, hasLength(3));
      expect(latLngs.first.latitude, 5.600);
      expect(latLngs.last.longitude, -0.180);

      final bounds = computeRouteBounds(latLngs);
      expect(bounds.$1.latitude, 5.600);
      expect(bounds.$2.latitude, 5.610);
    });
  });
}
