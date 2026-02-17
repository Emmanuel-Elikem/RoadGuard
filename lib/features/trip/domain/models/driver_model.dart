import 'package:hive/hive.dart';

part 'driver_model.g.dart';

/// Cached driver profile with aggregate rating data.
///
/// Stored in drivers_box, keyed by [plateNumber].
/// Updated locally after rating and synced from cloud.
@HiveType(typeId: 4)
class DriverModel extends HiveObject {
  @HiveField(0)
  final String plateNumber;

  @HiveField(1)
  int totalRatings;

  @HiveField(2)
  int goodRatings;

  @HiveField(3)
  int badRatings;

  @HiveField(4)
  List<String> commonTags;

  @HiveField(5)
  DateTime lastUpdated;

  @HiveField(6)
  String? region;

  DriverModel({
    this.plateNumber = '',
    this.totalRatings = 0,
    this.goodRatings = 0,
    this.badRatings = 0,
    this.commonTags = const [],
    DateTime? lastUpdated,
    this.region,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Percentage of good ratings (0.0-1.0).
  double get goodPercentage =>
      totalRatings > 0 ? goodRatings / totalRatings : 0.0;

  /// Applies a new rating to the aggregate.
  void applyRating(bool isGood, List<String> tags) {
    totalRatings++;
    if (isGood) {
      goodRatings++;
    } else {
      badRatings++;
    }

    // Update common tags — keep top 5
    final tagCounts = <String, int>{};
    for (final tag in commonTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    for (final tag in tags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    commonTags = sorted.take(5).map((e) => e.key).toList();
    lastUpdated = DateTime.now();
  }
}
