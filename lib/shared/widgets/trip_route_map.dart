/// Trip Route Map — Displays a completed trip's route on the map.
///
/// Shows the full polyline path with start/end markers.
/// Used in the trip summary/rating screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons/lucide_icons.dart';

import 'package:road_guard/core/theme/app_colors.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/features/trip/domain/models/route_point.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/widgets/roadguard_map.dart';

/// Displays a completed trip route on a map card.
///
/// Automatically fits the route bounds and shows start/end markers.
/// Falls back to a placeholder if no route data is available.
class TripRouteMap extends StatelessWidget {
  final TripModel trip;
  final double height;

  const TripRouteMap({
    super.key,
    required this.trip,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final routePoints = _getRoutePoints();
    if (routePoints == null || routePoints.length < 2) {
      return _NoRouteDataPlaceholder(height: height);
    }

    final latLngs = routePoints.toLatLngList();
    final bounds = _computeBounds(latLngs);
    final center = LatLng(
      (bounds.$1.latitude + bounds.$2.latitude) / 2,
      (bounds.$1.longitude + bounds.$2.longitude) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: SizedBox(
        height: height,
        child: RoadGuardMap(
          center: center,
          zoom: _computeZoom(bounds),
          routePoints: latLngs,
          showUserLocation: false,
          interactive: true,
          extraMarkers: _buildMarkers(latLngs),
        ),
      ),
    );
  }

  List<RoutePoint>? _getRoutePoints() {
    if (trip.routeData == null || trip.routeData!.isEmpty) return null;
    return decodeRoutePoints(trip.routeData!);
  }

  /// Compute bounding box (SW, NE corners) from a list of LatLngs.
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

  /// Estimate a zoom level that fits the route bounds.
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

  List<Marker> _buildMarkers(List<LatLng> points) {
    return [
      // Start marker
      Marker(
        point: points.first,
        width: AppDimensions.iconLg,
        height: AppDimensions.iconLg,
        child: _RouteEndpointMarker(
          icon: LucideIcons.play,
          color: AppColorsDark.primary,
          label: 'S',
        ),
      ),
      // End marker
      Marker(
        point: points.last,
        width: AppDimensions.iconLg,
        height: AppDimensions.iconLg,
        child: _RouteEndpointMarker(
          icon: LucideIcons.mapPin,
          color: AppColorsDark.error,
          label: 'E',
        ),
      ),
    ];
  }
}

/// Start/End route markers.
class _RouteEndpointMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RouteEndpointMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: AppDimensions.elevationMd,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: AppColorsDark.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14,
          ),
        ),
      ),
    );
  }
}

/// Placeholder shown when no route data is available.
class _NoRouteDataPlaceholder extends StatelessWidget {
  final double height;

  const _NoRouteDataPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.mapPinOff,
              size: AppDimensions.iconLg,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              'Route not recorded',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
