/// Unit tests for PlateSearchEngine fuzzy matching.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/utils/fuzzy_search.dart';

void main() {
  group('PlateSearchEngine.normalize', () {
    test('strips hyphens and spaces', () {
      expect(PlateSearchEngine.normalize('GR-1234-21'), 'GR123421');
    });

    test('uppercases', () {
      expect(PlateSearchEngine.normalize('gr 1234'), 'GR1234');
    });

    test('strips special chars', () {
      expect(PlateSearchEngine.normalize('GR@12#34'), 'GR1234');
    });
  });

  group('PlateSearchEngine.score', () {
    test('exact match = 1.0', () {
      expect(PlateSearchEngine.score('GR-1234-21', 'GR-1234-21'), 1.0);
    });

    test('exact match ignoring hyphens', () {
      expect(PlateSearchEngine.score('GR123421', 'GR-1234-21'), 1.0);
    });

    test('starts with scores 0.9', () {
      final s = PlateSearchEngine.score('GR12', 'GR-1234-21');
      expect(s, 0.9);
    });

    test('contains scores 0.8', () {
      final s = PlateSearchEngine.score('1234', 'GR-1234-21');
      expect(s, 0.8);
    });

    test('query longer than candidate — still matches', () {
      final s = PlateSearchEngine.score('GR123421XX', 'GR-1234-21');
      expect(s, greaterThanOrEqualTo(0.7));
    });

    test('same region with close digits — fuzzy match', () {
      // GR1245 vs GR1234 — same region, similar digits
      final s = PlateSearchEngine.score('GR1245', 'GR-1234-21');
      expect(s, greaterThan(0.0));
    });

    test('completely different — no match', () {
      final s = PlateSearchEngine.score('XX9999', 'GR-1234-21');
      expect(s, 0.0);
    });

    test('empty query = 0', () {
      expect(PlateSearchEngine.score('', 'GR-1234-21'), 0.0);
    });

    test('JR222 matches JR-222-xx', () {
      final s = PlateSearchEngine.score('JR222', 'JR-2220-19');
      expect(s, greaterThan(0.0));
    });

    test('region only matches all with that region', () {
      final s = PlateSearchEngine.score('GR', 'GR-5678-22');
      expect(s, 0.9); // starts with
    });
  });

  group('PlateSearchEngine.search', () {
    final plates = ['GR-1234-21', 'GR-5678-22', 'AS-1234-20', 'JR-2220-19'];

    test('returns matches sorted by relevance', () {
      final results = PlateSearchEngine.search<String>(
        query: 'GR1234',
        items: plates,
        getText: (p) => p,
      );

      expect(results, isNotEmpty);
      expect(results.first.item, 'GR-1234-21');
      expect(results.first.score, greaterThanOrEqualTo(0.9));
    });

    test('missing hyphens still matches', () {
      final results = PlateSearchEngine.search<String>(
        query: 'GR123421',
        items: plates,
        getText: (p) => p,
      );

      expect(results, isNotEmpty);
      expect(results.first.item, 'GR-1234-21');
    });

    test('empty query returns empty', () {
      final results = PlateSearchEngine.search<String>(
        query: '',
        items: plates,
        getText: (p) => p,
      );
      expect(results, isEmpty);
    });

    test('partial region matches multiple', () {
      final results = PlateSearchEngine.search<String>(
        query: 'GR',
        items: plates,
        getText: (p) => p,
      );
      // Should match both GR plates
      expect(results.length, greaterThanOrEqualTo(2));
    });
  });
}
