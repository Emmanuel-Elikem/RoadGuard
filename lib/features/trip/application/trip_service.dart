import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:road_guard/features/trip/data/repositories/trip_repository.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/services/location_service.dart';
import 'package:road_guard/shared/services/storage_service.dart';
import 'package:uuid/uuid.dart';

part 'trip_service.g.dart';

enum TripState { idle, recording, paused }

@Riverpod(keepAlive: true)
class TripController extends _$TripController {
  Timer? _timer;
  DateTime? _startTime;
  TripModel? _currentTrip;
  List<SpeedReading> _routePoints = [];
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0; // In meters
  
  @override
  TripState build() {
    // Check if there's an active trip in storage (crash recovery - for future)
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
      userId: ref.read(storageServiceProvider).userId ?? 'guest', // robust fallback
      startTime: _startTime!,
    );
    _routePoints = [];
    _maxSpeed = 0.0;
    _totalDistance = 0.0;
    
    // Start listening to location updates
    final locationService = ref.read(locationServiceProvider);
    locationService.speedStream?.listen(_onLocationUpdate);

    _startTimer();
    state = TripState.recording;
  }

  Future<void> stopTrip() async {
    if (state == TripState.idle) return;

    _stopTimer();
    
    // Finalize trip data
    final endTime = DateTime.now();
    
    // Calculate final stats
    // Average speed could be calculated from total distance / duration
    // or from the average of all speed points. Distance/Duration is safer.
    final durationSeconds = endTime.difference(_startTime!).inSeconds;
    final avgSpeed = durationSeconds > 0 ? _totalDistance / durationSeconds : 0.0;

    _currentTrip = _currentTrip!.copyWith(
      endTime: endTime,
      distance: _totalDistance / 1000.0, // km
      maxSpeed: _maxSpeed, // m/s
      avgSpeed: avgSpeed, // m/s
    );

    // We don't save yet - we wait for user to rate/confirm in Summary Screen
    // But we could save a "draft" or "pending" trip here if we wanted crash recovery.
    // For MVP, we pass this trip to the summary screen.
    
    state = TripState.idle;
  }

  Future<void> saveCompletedTrip(TripModel trip) async {
    await ref.read(tripRepositoryProvider).saveTrip(trip);
  }

  void _onLocationUpdate(SpeedReading reading) {
    if (state != TripState.recording) return;

    // Filter poor accuracy
    if (reading.accuracy > 50) return; // Ignore points with > 50m inaccuracy (Ghana edge case)

    // Update Max Speed
    if (reading.speedMs > _maxSpeed) {
      _maxSpeed = reading.speedMs;
    }

    // Calculate distance
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      final distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        reading.latitude,
        reading.longitude,
      );
      _totalDistance += distance;
    }

    _routePoints.add(reading);
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
