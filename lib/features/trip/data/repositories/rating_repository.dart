/// Rating Repository — offline-first rating storage with driver aggregation.
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/services/storage_service.dart';
import '../../domain/models/driver_model.dart';
import '../../domain/models/rating_model.dart';

part 'rating_repository.g.dart';

@riverpod
RatingRepository ratingRepository(ref) {
  return RatingRepository(StorageService.instance);
}

class RatingRepository {
  final StorageService _storage;

  RatingRepository(this._storage);

  /// Saves a rating and updates the driver's aggregate.
  Future<void> saveRating(RatingModel rating) async {
    // Save to ratings_box
    await _storage.ratingsBox.put(rating.id, rating);

    // Update driver aggregate
    var driver = _storage.driversBox.get(rating.plateNumber);
    if (driver == null) {
      driver = DriverModel(plateNumber: rating.plateNumber);
      driver.applyRating(rating.isGood, rating.tags);
      await _storage.driversBox.put(rating.plateNumber, driver);
    } else {
      driver.applyRating(rating.isGood, rating.tags);
      await driver.save();
    }

    debugPrint(
      'Rating saved: ${rating.plateNumber} '
      '${rating.isGood ? "good" : "bad"} '
      '(driver total: ${driver.totalRatings})',
    );
  }

  /// Gets all ratings for a specific plate number.
  List<RatingModel> getRatingsForPlate(String plateNumber) {
    return _storage.ratingsBox.values
        .where((r) => r.plateNumber == plateNumber)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Gets a driver model by plate number.
  DriverModel? getDriver(String plateNumber) {
    return _storage.driversBox.get(plateNumber);
  }

  /// Searches drivers by plate number prefix.
  List<DriverModel> searchDrivers(String query) {
    final normalized = query.toUpperCase().trim();
    if (normalized.isEmpty) return [];

    return _storage.driversBox.values
        .where((d) =>
            d.plateNumber.toUpperCase().contains(normalized))
        .toList()
      ..sort((a, b) => b.totalRatings.compareTo(a.totalRatings));
  }

  /// Gets all user's ratings (most recent first).
  List<RatingModel> getAllRatings() {
    return _storage.ratingsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Gets unsynced ratings for cloud sync.
  List<RatingModel> getUnsyncedRatings() {
    return _storage.ratingsBox.values
        .where((r) => !r.isSynced)
        .toList();
  }
}
