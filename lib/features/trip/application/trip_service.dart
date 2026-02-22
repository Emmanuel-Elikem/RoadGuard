import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:road_guard/features/trip/data/repositories/trip_repository.dart';
import 'package:road_guard/features/trip/domain/models/route_point.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/services/location_service.dart';
import 'package:road_guard/shared/services/storage_service.dart';
import 'package:uuid/uuid.dart';

part 'trip_service.g.dart';

enum TripState { idle, recording, paused }

/// Keys for persisting in-progress trip data to Hive settings box.
const String _kDraftTripId = 'draft_trip_id';
const String _kDraftTripUserId = 'draft_trip_user_id';
const String _kDraftTripStartTime = 'draft_trip_start_time';
const String _kDraftTripRoutePoints = 'draft_trip_route_points';
const String _kDraftTripMaxSpeed = 'draft_trip_max_speed';
const String _kDraftTripDistance = 'draft_trip_distance';

@Riverpod(keepAlive: true)
class TripController extends _$TripController {
  Timer? _timer;
  Timer? _persistTimer;
  StreamSubscription<SpeedReading>? _locationSubscription;
  DateTime? _startTime;
  TripModel? _currentTrip;
  List<SpeedReading> _routePoints = [];
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0; // In meters
  
  @override
  TripState build() {
    ref.onDispose(() {
      _locationSubscription?.cancel();
      _timer?.cancel();
      _persistTimer?.cancel();
    });
    return TripState.idle;
  }

  TripModel? get currentTrip => _currentTrip;
  Duration get currentDuration => _startTime == null 
      ? Duration.zero 
      : DateTime.now().difference(_startTime!);
  double get currentDistance => _totalDistance / 1000.0; // km
  double get currentMaxSpeed => _maxSpeed * 3.6; // km/h

  void startTrip() {
    if (state == TripState.recording) return;

    _startTime = DateTime.now();
    _currentTrip = TripModel(
      id: const Uuid().v4(),
      userId: ref.read(storageServiceProvider).userId ?? 'guest',
      startTime: _startTime!,
    );
    _routePoints = [];
    _maxSpeed = 0.0;
    _totalDistance = 0.0;

    // Set state BEFORE subscribing so _onLocationUpdate doesn't drop events
    state = TripState.recording;
    
    // Persist draft immediately so it survives app kill
    _persistDraftTrip();
    
    // Subscribe to location updates from the shared broadcast stream
    _locationSubscription?.cancel();
    final locationService = ref.read(locationServiceProvider);
    final stream = locationService.speedStream;
    if (stream != null) {
      _locationSubscription = stream.listen(_onLocationUpdate);
      debugPrint('TripController: Subscribed to location stream');
    } else {
      debugPrint('TripController: WARNING - speed stream is null!');
    }

    _startTimer();
    _startPersistTimer();
  }

  Future<void> stopTrip() async {
    if (state == TripState.idle) return;

    _stopTimer();
    _stopPersistTimer();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    
    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(_startTime!).inSeconds;
    final avgSpeed = durationSeconds > 0 ? _totalDistance / durationSeconds : 0.0;

    debugPrint('TripController: Stopping trip - '
        'points=${_routePoints.length}, '
        'distance=${(_totalDistance / 1000).toStringAsFixed(3)} km, '
        'maxSpeed=${(_maxSpeed * 3.6).toStringAsFixed(1)} km/h');

    _currentTrip = _currentTrip!.copyWith(
      endTime: endTime,
      distance: _totalDistance / 1000.0,
      maxSpeed: _maxSpeed,
      avgSpeed: avgSpeed,
      routeData: _routePoints
          .map((r) => RoutePoint(
                latitude: r.latitude,
                longitude: r.longitude,
                speedMs: r.speedMs,
              ))
          .toList()
          .encode(),
    );
    
    // Clear draft — trip is now finalized
    _clearDraftTrip();
    
    state = TripState.idle;
  }

  Future<void> saveCompletedTrip(TripModel trip) async {
    await ref.read(tripRepositoryProvider).saveTrip(trip);
  }

  void _onLocationUpdate(SpeedReading reading) {
    if (state != TripState.recording) return;

    // Filter poor accuracy (relaxed for Ghana conditions)
    if (reading.accuracy > 100) return;

    if (reading.speedMs > _maxSpeed) {
      _maxSpeed = reading.speedMs;
    }

    // Calculate distance from previous point
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      final distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        reading.latitude,
        reading.longitude,
      );
      // Filter GPS jitter: ignore tiny movements < 2m
      if (distance > 2.0) {
        _totalDistance += distance;
      }
    }

    _routePoints.add(reading);
    debugPrint('TripController: point #${_routePoints.length}, '
        'dist=${(_totalDistance / 1000).toStringAsFixed(3)} km');
  }

  // ===========================================================================
  // TRIP PERSISTENCE — survives app kill
  // ===========================================================================

  /// Persist current trip state to Hive so it can be resumed after app kill.
  void _persistDraftTrip() {
    if (_currentTrip == null || _startTime == null) return;
    try {
      final storage = ref.read(storageServiceProvider);
      final settingsBox = storage.settingsBox;
      settingsBox.put(_kDraftTripId, _currentTrip!.id);
      settingsBox.put(_kDraftTripUserId, _currentTrip!.userId);
      settingsBox.put(_kDraftTripStartTime, _startTime!.toIso8601String());
      settingsBox.put(_kDraftTripMaxSpeed, _maxSpeed);
      settingsBox.put(_kDraftTripDistance, _totalDistance);

      // Encode route points as JSON string (Hive can't store List<Map>)
      final routeJson = _routePoints
          .map((r) => '${r.latitude},${r.longitude},${r.speedMs}')
          .join(';');
      settingsBox.put(_kDraftTripRoutePoints, routeJson);

      debugPrint('TripController: Draft persisted '
          '(${_routePoints.length} points, '
          '${(_totalDistance / 1000).toStringAsFixed(2)} km)');
    } catch (e) {
      debugPrint('TripController: Failed to persist draft: $e');
    }
  }

  /// Clear the draft trip from Hive (called after stop or discard).
  void _clearDraftTrip() {
    try {
      final storage = ref.read(storageServiceProvider);
      final settingsBox = storage.settingsBox;
      settingsBox.delete(_kDraftTripId);
      settingsBox.delete(_kDraftTripUserId);
      settingsBox.delete(_kDraftTripStartTime);
      settingsBox.delete(_kDraftTripRoutePoints);
      settingsBox.delete(_kDraftTripMaxSpeed);
      settingsBox.delete(_kDraftTripDistance);
      debugPrint('TripController: Draft cleared');
    } catch (e) {
      debugPrint('TripController: Failed to clear draft: $e');
    }
  }

  /// Called on app lifecycle pause/detach to flush immediately.
  void onAppLifecyclePaused() {
    if (state == TripState.recording) {
      _persistDraftTrip();
      debugPrint('TripController: Flushed draft on lifecycle pause');
    }
  }

  /// Check for a persisted draft trip and resume it.
  ///
  /// Returns the recovered [TripModel] if a draft was found (already finalized
  /// with endTime = now), or null if no draft exists.
  /// The caller should present this trip for saving/rating.
  TripModel? recoverDraftTrip() {
    try {
      final storage = ref.read(storageServiceProvider);
      final settingsBox = storage.settingsBox;
      final draftId = settingsBox.get(_kDraftTripId) as String?;
      if (draftId == null) return null;

      final userId =
          settingsBox.get(_kDraftTripUserId, defaultValue: 'guest') as String;
      final startTimeStr = settingsBox.get(_kDraftTripStartTime) as String?;
      if (startTimeStr == null) {
        _clearDraftTrip();
        return null;
      }

      final startTime = DateTime.parse(startTimeStr);
      final maxSpeed =
          (settingsBox.get(_kDraftTripMaxSpeed, defaultValue: 0.0) as num)
              .toDouble();
      final totalDistance =
          (settingsBox.get(_kDraftTripDistance, defaultValue: 0.0) as num)
              .toDouble();
      final routeJson =
          settingsBox.get(_kDraftTripRoutePoints, defaultValue: '') as String;

      // Decode route points
      List<double>? routeData;
      if (routeJson.isNotEmpty) {
        final points = <RoutePoint>[];
        for (final entry in routeJson.split(';')) {
          if (entry.isEmpty) continue;
          final parts = entry.split(',');
          if (parts.length == 3) {
            points.add(RoutePoint(
              latitude: double.parse(parts[0]),
              longitude: double.parse(parts[1]),
              speedMs: double.parse(parts[2]),
            ));
          }
        }
        if (points.isNotEmpty) {
          routeData = points.encode();
        }
      }

      final endTime = DateTime.now();
      final durationSeconds = endTime.difference(startTime).inSeconds;
      final avgSpeed =
          durationSeconds > 0 ? totalDistance / durationSeconds : 0.0;

      final recoveredTrip = TripModel(
        id: draftId,
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        distance: totalDistance / 1000.0,
        maxSpeed: maxSpeed,
        avgSpeed: avgSpeed,
        routeData: routeData,
      );

      // Clear the draft now that we've recovered it
      _clearDraftTrip();

      debugPrint('TripController: Recovered draft trip $draftId '
          '(started ${startTime.toIso8601String()})');

      return recoveredTrip;
    } catch (e) {
      debugPrint('TripController: Failed to recover draft: $e');
      _clearDraftTrip();
      return null;
    }
  }

  /// Start periodic flush timer (every 30s).
  void _startPersistTimer() {
    _persistTimer?.cancel();
    _persistTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _persistDraftTrip();
    });
  }

  void _stopPersistTimer() {
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Trigger rebuild to update duration UI
      // In a real app we might use a separate ticker provider to avoid rebuilding everything
      ref.notifyListeners(); 
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

// Separate provider for the ticker to avoid rebuilding the main controller too often?
// For MVP, ref.notifyListeners() in the controller is fine, but let's be careful.
// Better: Expose a stream of duration.

@riverpod
Stream<Duration> tripDuration(Ref ref) async* {
  final tripState = ref.watch(tripControllerProvider);
  if (tripState == TripState.recording) {
    // Yield duration every second
    final startTime = ref.read(tripControllerProvider.notifier)._startTime;
    if (startTime != null) {
      while (true) {
        if (ref.read(tripControllerProvider) != TripState.recording) break;
        yield DateTime.now().difference(startTime);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  } else {
    yield Duration.zero;
  }
}
