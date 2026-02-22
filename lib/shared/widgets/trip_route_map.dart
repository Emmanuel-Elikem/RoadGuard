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
import 'package:road_guard/shared/utils/map_geometry.dart';
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
    final bounds = computeRouteBounds(latLngs);
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
          zoom: computeRouteZoom(bounds),
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
