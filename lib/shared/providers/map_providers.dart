/// Map Providers — Riverpod providers for map state management.
///
/// Manages the current map position, tracking state, and
/// connectivity-aware tile source selection.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:road_guard/features/tracking/domain/providers/tracking_providers.dart';


part 'map_providers.g.dart';

/// Default center point: Accra, Ghana.
const LatLng kDefaultCenter = LatLng(5.6037, -0.1870);

/// Default zoom level for city-scale view.
const double kDefaultZoom = 15.0;

/// Zoom level when tracking is active (closer view).
const double kTrackingZoom = 17.0;

/// Minimum zoom level.
const double kMinZoom = 4.0;

/// Maximum zoom level.
const double kMaxZoom = 18.0;

/// Current user position as LatLng, derived from the speed tracking stream.
@riverpod
LatLng? currentLatLng(Ref ref) {
  final speedState = ref.watch(speedTrackingProvider);
  final reading = speedState.currentReading;
  if (reading == null || !reading.hasGpsData) return null;
  return LatLng(reading.latitude, reading.longitude);
}

/// Current heading in degrees from GPS, for rotating the user marker.
@riverpod
double currentHeading(Ref ref) {
  final speedState = ref.watch(speedTrackingProvider);
  return speedState.currentReading?.heading ?? 0.0;
}

/// Whether the map should follow the user's position (auto-center).
@Riverpod(keepAlive: true)
class MapFollowUser extends _$MapFollowUser {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void enable() => state = true;
  void disable() => state = false;
}
