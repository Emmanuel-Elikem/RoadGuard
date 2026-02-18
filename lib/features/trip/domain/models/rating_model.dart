import 'package:hive/hive.dart';

/// A driver rating submitted by a passenger.
///
/// Standalone model stored in ratings_box.
/// Links to a driver via [plateNumber] and optionally to a trip.
@HiveType(typeId: 2)
class RatingModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String plateNumber;

  @HiveField(2)
  final String? raterId;

  @HiveField(3)
  final bool isGood;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final String? comment;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final double? lat;

  @HiveField(8)
  final double? lng;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  DateTime? syncedAt;

  @HiveField(11)
  final String? tripId;

  RatingModel({
    this.id = '',
    this.plateNumber = '',
    this.raterId,
    this.isGood = true,
    this.tags = const [],
    this.comment,
    DateTime? createdAt,
    this.lat,
    this.lng,
    this.isSynced = false,
    this.syncedAt,
    this.tripId,
  }) : createdAt = createdAt ?? DateTime.now();
}
