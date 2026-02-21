import 'package:hive/hive.dart';

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

  @HiveField(7)
  Map<String, int> tagFrequency;

  DriverModel({
    this.plateNumber = '',
    this.totalRatings = 0,
    this.goodRatings = 0,
    this.badRatings = 0,
    this.commonTags = const [],
    DateTime? lastUpdated,
    this.region,
    Map<String, int>? tagFrequency,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        tagFrequency = tagFrequency ?? {};

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

    // Accumulate tag counts in the frequency map
    for (final tag in tags) {
      tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
    }

    // Derive top 5 tags from frequency map
    final sorted = tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    commonTags = sorted.take(5).map((e) => e.key).toList();
    lastUpdated = DateTime.now();
  }
}
