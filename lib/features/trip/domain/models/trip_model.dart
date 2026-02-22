import 'package:hive/hive.dart';

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
  final String? ratingId; // Reference to standalone RatingModel

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final String? plateNumber;

  @HiveField(11)
  final List<double>? routeData;

  TripModel({
    this.id = '',
    this.userId = '',
    DateTime? startTime,
    this.endTime,
    this.distance = 0.0,
    this.maxSpeed = 0.0,
    this.avgSpeed = 0.0,
    this.ratingId,
    this.notes,
    this.isSynced = false,
    this.plateNumber,
    this.routeData,
  }) : startTime = startTime ?? DateTime.now();

  TripModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    double? maxSpeed,
    double? avgSpeed,
    String? ratingId,
    String? notes,
    bool? isSynced,
    String? plateNumber,
    List<double>? routeData,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      ratingId: ratingId ?? this.ratingId,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      plateNumber: plateNumber ?? this.plateNumber,
      routeData: routeData ?? this.routeData,
    );
  }
}
