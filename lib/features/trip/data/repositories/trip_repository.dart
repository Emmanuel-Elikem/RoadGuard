import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/services/storage_service.dart';

part 'trip_repository.g.dart';

class TripRepository {
  final Box<TripModel> _tripsBox;

  TripRepository(this._tripsBox);

  Future<void> saveTrip(TripModel trip) async {
    await _tripsBox.put(trip.id, trip);
  }

  Future<void> deleteTrip(String id) async {
    await _tripsBox.delete(id);
  }

  TripModel? getTrip(String id) {
    return _tripsBox.get(id);
  }

  List<TripModel> getAllTrips() {
    return _tripsBox.values.toList();
  }

  /// Watch trips stream for reactive UI updates
  Stream<List<TripModel>> watchTrips() async* {
    yield getAllTrips();
    yield* _tripsBox.watch().map((event) => getAllTrips());
  }
}

@Riverpod(keepAlive: true)
TripRepository tripRepository(Ref ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TripRepository(storageService.tripsBox);
}
