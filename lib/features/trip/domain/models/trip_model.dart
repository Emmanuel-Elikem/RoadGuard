import 'package:hive/hive.dart';
import 'rating_model.dart';
// import 'route_point_model.dart'; // Will add later if needed

part 'trip_model.g.dart';

@HiveType(typeId: 3)
class TripModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime? endTime;

  @HiveField(4)
  final double distance; // in km

  @HiveField(5)
  final double maxSpeed; // in m/s

  @HiveField(6)
  final double avgSpeed; // in m/s

  @HiveField(7)
  final RatingModel? rating;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final bool isSynced;

  TripModel({
    this.id = '',
    this.userId = '',
    DateTime? startTime,
    this.endTime,
    this.distance = 0.0,
    this.maxSpeed = 0.0,
    this.avgSpeed = 0.0,
    this.rating,
    this.notes,
    this.isSynced = false,
  }) : startTime = startTime ?? DateTime.now();

  TripModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? maxSpeed,
    double? avgSpeed,
    RatingModel? rating,
    String? notes,
    bool? isSynced,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
