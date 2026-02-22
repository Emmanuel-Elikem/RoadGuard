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

@Riverpod(keepAlive: true)
class TripController extends _$TripController {
  Timer? _timer;
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
  }

  Future<void> stopTrip() async {
    if (state == TripState.idle) return;

    _stopTimer();
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
