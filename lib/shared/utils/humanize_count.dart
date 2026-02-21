/// Formatting utilities for human-readable numbers.
library;

/// Formats large numbers into human-friendly approximations.
///
/// - Under 100: exact value ("42 trips")
/// - 100–999: rounds down to nearest 100 ("Over 200 trips")
/// - 1,000–999,999: rounds to nearest K ("Over 5K trips")
/// - 1,000,000+: rounds to nearest M ("Over 2M trips")
String humanizeCount(int count, {String suffix = ''}) {
  final s = suffix.isNotEmpty ? ' $suffix' : '';

  if (count < 100) return '$count$s';

  if (count < 1000) {
    final rounded = (count ~/ 100) * 100;
    return 'Over $rounded$s';
  }

  if (count < 1000000) {
    final k = count ~/ 1000;
    return 'Over ${k}K$s';
  }

  final m = count ~/ 1000000;
  return 'Over ${m}M$s';
}
