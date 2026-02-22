/// Route Point — A lightweight GPS point recorded during a trip.
///
/// Stored as part of TripModel for route visualization.
/// Deliberately minimal to keep storage small.
library;

import 'package:latlong2/latlong.dart';

/// A single point on a trip route with speed data.
class RoutePoint {
  final double latitude;
  final double longitude;

  /// Speed at this point in m/s.
  final double speedMs;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.speedMs,
  });

  /// Convert to LatLng for map rendering.
  LatLng get latLng => LatLng(latitude, longitude);

  /// Speed in km/h for display.
  double get speedKmh => speedMs * 3.6;

  /// Encode as a flat list [lat, lng, speed] for Hive storage.
  List<double> toList() => [latitude, longitude, speedMs];

  /// Decode from a flat list [lat, lng, speed].
  factory RoutePoint.fromList(List<double> data) {
    assert(data.length == 3, 'RoutePoint requires exactly 3 values');
    return RoutePoint(
      latitude: data[0],
      longitude: data[1],
      speedMs: data[2],
    );
  }

  @override
  String toString() =>
      'RoutePoint($latitude, $longitude, ${speedKmh.toStringAsFixed(1)} km/h)';
}

/// Extension to convert a list of RoutePoints to/from Hive-compatible format.
extension RoutePointListX on List<RoutePoint> {
  /// Encode all points as a flat `List<double>` for Hive storage.
  /// Format: `[lat1, lng1, speed1, lat2, lng2, speed2, ...]`
  List<double> encode() {
    final result = <double>[];
    for (final point in this) {
      result.addAll(point.toList());
    }
    return result;
  }

  /// Extract LatLng list for polyline rendering.
  List<LatLng> toLatLngList() => map((p) => p.latLng).toList();
}

/// Decode a flat double list back into RoutePoints.
List<RoutePoint> decodeRoutePoints(List<double> data) {
  final points = <RoutePoint>[];
  for (int i = 0; i + 2 < data.length; i += 3) {
    points.add(RoutePoint.fromList(data.sublist(i, i + 3)));
  }
  return points;
}
