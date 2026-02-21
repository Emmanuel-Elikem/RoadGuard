/// Unit tests for humanizeCount.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/utils/humanize_count.dart';

void main() {
  group('humanizeCount', () {
    test('exact for small numbers', () {
      expect(humanizeCount(0, suffix: 'trips'), '0 trips');
      expect(humanizeCount(5, suffix: 'trips'), '5 trips');
      expect(humanizeCount(42, suffix: 'trips'), '42 trips');
      expect(humanizeCount(99, suffix: 'trips'), '99 trips');
    });

    test('rounds to hundreds for 100-999', () {
      expect(humanizeCount(100, suffix: 'trips'), 'Over 100 trips');
      expect(humanizeCount(150, suffix: 'trips'), 'Over 100 trips');
      expect(humanizeCount(250, suffix: 'trips'), 'Over 200 trips');
      expect(humanizeCount(999, suffix: 'trips'), 'Over 900 trips');
    });

    test('rounds to K for 1000-999999', () {
      expect(humanizeCount(1000, suffix: 'trips'), 'Over 1K trips');
      expect(humanizeCount(1200, suffix: 'trips'), 'Over 1K trips');
      expect(humanizeCount(5500, suffix: 'trips'), 'Over 5K trips');
      expect(humanizeCount(999999, suffix: 'trips'), 'Over 999K trips');
    });

    test('rounds to M for 1000000+', () {
      expect(humanizeCount(1000000, suffix: 'trips'), 'Over 1M trips');
      expect(humanizeCount(2500000, suffix: 'trips'), 'Over 2M trips');
    });

    test('works without suffix', () {
      expect(humanizeCount(42), '42');
      expect(humanizeCount(1200), 'Over 1K');
    });

    test('singular suffix', () {
      expect(humanizeCount(1, suffix: 'trip'), '1 trip');
    });
  });
}
