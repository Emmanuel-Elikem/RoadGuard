import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_guard/features/trip/domain/models/route_point.dart';

/// Tests for route visualization logic used in TripRouteMap.
///
/// These test the bounds and zoom computation algorithms
/// independently from the widget tree.
void main() {
  group('Route bounds computation', () {
    test('single point returns identical SW and NE', () {
      final points = [const LatLng(5.6037, -0.1870)];
      final bounds = _computeBounds(points);
      expect(bounds.$1, equals(bounds.$2));
    });

    test('two-point route computes correct SW/NE', () {
      final points = [
        const LatLng(5.60, -0.19),
        const LatLng(5.62, -0.17),
      ];
      final bounds = _computeBounds(points);
      expect(bounds.$1.latitude, 5.60); // SW lat
      expect(bounds.$1.longitude, -0.19); // SW lng
      expect(bounds.$2.latitude, 5.62); // NE lat
      expect(bounds.$2.longitude, -0.17); // NE lng
    });

    test('multi-point route finds extremes', () {
      final points = [
        const LatLng(5.60, -0.19),
        const LatLng(5.58, -0.20), // south + west
        const LatLng(5.64, -0.15), // north + east
        const LatLng(5.61, -0.18),
      ];
      final bounds = _computeBounds(points);
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
      expect(_computeZoom(bounds), 17.0);
    });

    test('medium route (0.01-0.02°) gets zoom 14', () {
      final bounds = (
        const LatLng(5.60, -0.19),
        const LatLng(5.61, -0.18),
      );
      expect(_computeZoom(bounds), 14.0);
    });

    test('large route (> 0.2°) gets zoom 10', () {
      final bounds = (
        const LatLng(5.50, -0.30),
        const LatLng(5.80, -0.10),
      );
      expect(_computeZoom(bounds), 10.0);
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

      // Verify bounds computation works with decoded points
      final bounds = _computeBounds(latLngs);
      expect(bounds.$1.latitude, 5.600);
      expect(bounds.$2.latitude, 5.610);
    });
  });
}

// Extracted logic from TripRouteMap for testability.
(LatLng, LatLng) _computeBounds(List<LatLng> points) {
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  return (LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

double _computeZoom((LatLng, LatLng) bounds) {
  final latDiff = (bounds.$2.latitude - bounds.$1.latitude).abs();
  final lngDiff = (bounds.$2.longitude - bounds.$1.longitude).abs();
  final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

  if (maxDiff < 0.002) return 17.0;
  if (maxDiff < 0.005) return 16.0;
  if (maxDiff < 0.01) return 15.0;
  if (maxDiff < 0.02) return 14.0;
  if (maxDiff < 0.05) return 13.0;
  if (maxDiff < 0.1) return 12.0;
  if (maxDiff < 0.2) return 11.0;
  return 10.0;
}
