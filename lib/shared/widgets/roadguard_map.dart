/// RoadGuard Map Widget — Offline-first OpenStreetMap with FMTC caching.
///
/// Uses flutter_map with FMTC tile caching so maps work even
/// without internet. Shows the user's live position when tracking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:road_guard/core/theme/app_colors.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/shared/providers/map_providers.dart';
import 'package:road_guard/shared/services/map_tile_service.dart' show kDefaultTileStoreName, mapTileServiceProvider;

/// A reusable map widget that handles tile caching, user location,
/// and route polylines.
///
/// [center] — Initial center of the map.
/// [zoom] — Initial zoom level.
/// [routePoints] — Optional list of points to draw as a polyline.
/// [showUserLocation] — Whether to show the user's live position.
/// [interactive] — Whether the user can pan/zoom.
/// [onMapReady] — Callback when the map controller is ready.
/// [mapController] — External controller for programmatic map control.
class RoadGuardMap extends ConsumerStatefulWidget {
  final LatLng? center;
  final double zoom;
  final List<LatLng>? routePoints;
  final bool showUserLocation;
  final bool interactive;
  final VoidCallback? onMapReady;
  final MapController? mapController;
  final List<Marker>? extraMarkers;

  const RoadGuardMap({
    super.key,
    this.center,
    this.zoom = kDefaultZoom,
    this.routePoints,
    this.showUserLocation = true,
    this.interactive = true,
    this.onMapReady,
    this.mapController,
    this.extraMarkers,
  });

  @override
  ConsumerState<RoadGuardMap> createState() => _RoadGuardMapState();
}

class _RoadGuardMapState extends ConsumerState<RoadGuardMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();

    // Listen for position changes and auto-center when following.
    // Using ref.listenManual avoids the postFrameCallback-per-build issue.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.showUserLocation) return;
      ref.listenManual(currentLatLngProvider, (prev, next) {
        if (!mounted) return;
        final follow = ref.read(mapFollowUserProvider);
        if (follow && next != null) {
          try {
            _mapController.move(next, _mapController.camera.zoom);
          } catch (_) {}
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = widget.showUserLocation
        ? ref.watch(currentLatLngProvider)
        : null;
    final heading = widget.showUserLocation
        ? ref.watch(currentHeadingProvider)
        : 0.0;
    final followUser = ref.watch(mapFollowUserProvider);

    final effectiveCenter = widget.center ?? userLatLng ?? kDefaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: effectiveCenter,
        initialZoom: widget.zoom,
        minZoom: kMinZoom,
        maxZoom: kMaxZoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
        onPositionChanged: (position, hasGesture) {
          // Disable auto-follow when user manually drags the map
          if (hasGesture && followUser) {
            ref.read(mapFollowUserProvider.notifier).disable();
          }
        },
      ),
      children: [
        // Tile layer with FMTC caching
        _buildTileLayer(),

        // Route polyline
        if (widget.routePoints != null && widget.routePoints!.isNotEmpty)
          _buildRouteLayer(),

        // User location marker
        if (userLatLng != null) _buildUserMarker(userLatLng, heading),

        // Extra markers (start/end points, etc.)
        if (widget.extraMarkers != null && widget.extraMarkers!.isNotEmpty)
          MarkerLayer(markers: widget.extraMarkers!),
      ],
    );
  }

  /// Tile layer with FMTC offline caching.
  Widget _buildTileLayer() {
    final tileService = ref.read(mapTileServiceProvider);

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.roadguard.app',
      maxZoom: kMaxZoom,
      tileProvider: tileService.isInitialized
          ? FMTCTileProvider(
              stores: {kDefaultTileStoreName: BrowseStoreStrategy.readUpdate},
            )
          : NetworkTileProvider(),
    );
  }

  /// Route polyline layer.
  Widget _buildRouteLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.routePoints!,
          strokeWidth: 4.0,
          color: AppColorsDark.primary,
          borderStrokeWidth: 1.5,
          borderColor: AppColorsDark.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  /// User location marker with heading indicator.
  Widget _buildUserMarker(LatLng position, double heading) {
    return MarkerLayer(
      markers: [
        Marker(
          point: position,
          width: AppDimensions.iconXl,
          height: AppDimensions.iconXl,
          child: _UserLocationDot(heading: heading),
        ),
      ],
    );
  }
}

/// Animated user location dot with heading direction arrow.
class _UserLocationDot extends StatelessWidget {
  final double heading;

  const _UserLocationDot({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: AppDimensions.iconXl,
          height: AppDimensions.iconXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorsDark.secondary.withValues(alpha: 0.15),
          ),
        ),
        // Heading direction cone
        if (heading != 0)
          Transform.rotate(
            angle: heading * (3.14159265 / 180),
            child: CustomPaint(
              size: const Size(AppDimensions.iconLg, AppDimensions.iconLg),
              painter: _HeadingConePainter(),
            ),
          ),
        // Inner dot
        Container(
          width: AppDimensions.iconSm,
          height: AppDimensions.iconSm,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorsDark.secondary,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColorsDark.secondary.withValues(alpha: 0.4),
                blurRadius: AppDimensions.elevationMd,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints a semi-transparent heading cone pointing upward (north).
class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColorsDark.secondary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.35, size.height * 0.4)
      ..lineTo(size.width * 0.65, size.height * 0.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
