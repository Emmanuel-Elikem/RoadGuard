import 'package:hive/hive.dart';

part 'rating_model.g.dart';

@HiveType(typeId: 2) // Using ID 2
class RatingModel extends HiveObject {
  @HiveField(0)
  final int rating; // 1-5

  @HiveField(1)
  final List<String> tags;

  @HiveField(2)
  final String? comment;

  @HiveField(3)
  final DateTime timestamp;

  RatingModel({
    this.rating = 0,
    this.tags = const [],
    this.comment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
