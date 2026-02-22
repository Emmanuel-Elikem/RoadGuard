/// Map Geometry Helpers — Shared bounds and zoom computation.
///
/// Extracted from TripRouteMap so production code and tests
/// use the same logic.
library;

import 'package:latlong2/latlong.dart';

/// Compute bounding box (SW, NE corners) from a list of LatLngs.
(LatLng, LatLng) computeRouteBounds(List<LatLng> points) {
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

/// Estimate a zoom level that fits the given route bounds.
double computeRouteZoom((LatLng, LatLng) bounds) {
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
