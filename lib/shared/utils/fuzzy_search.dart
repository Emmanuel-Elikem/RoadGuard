/// Fuzzy search utilities for plate number matching.
///
/// Handles real-world input variations: missing hyphens,
/// extra spaces, typos, partial input, and character swaps.
library;

/// A search result with a relevance score for ranking.
class FuzzyMatch<T> {
  final T item;

  /// 0.0 = no match, 1.0 = exact match. Higher = more relevant.
  final double score;

  const FuzzyMatch(this.item, this.score);
}

/// Fuzzy search engine for plate numbers.
///
/// Strips formatting, compares raw alphanumeric characters,
/// and scores results by relevance.
class PlateSearchEngine {
  /// Strips all non-alphanumeric characters and uppercases.
  static String normalize(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  /// Scores how well [candidate] matches [query].
  ///
  /// Returns 0.0 for no match, up to 1.0 for exact match.
  /// Scoring tiers:
  ///   1.0  — exact match (normalized)
  ///   0.9  — candidate starts with query
  ///   0.8  — candidate contains query as substring
  ///   0.7  — query contains candidate (user typed more than exists)
  ///   0.3–0.6 — fuzzy match (allows character insertions/deletions)
  static double score(String query, String candidate) {
    final q = normalize(query);
    final c = normalize(candidate);

    if (q.isEmpty || c.isEmpty) return 0.0;

    // Exact match
    if (q == c) return 1.0;

    // Starts with
    if (c.startsWith(q)) return 0.9;

    // Contains
    if (c.contains(q)) return 0.8;

    // Query contains candidate (user typed candidate + extra chars)
    if (q.contains(c)) return 0.7;

    // Starts-with on the raw region prefix
    if (q.length >= 2 && c.length >= 2 && q.substring(0, 2) == c.substring(0, 2)) {
      // Same region — check digits portion
      final qDigits = q.substring(2);
      final cDigits = c.substring(2);
      if (cDigits.startsWith(qDigits) || qDigits.startsWith(cDigits)) {
        return 0.75;
      }
      // Fuzzy on the digits portion
      final dist = _editDistance(qDigits, cDigits);
      final maxLen = qDigits.length > cDigits.length ? qDigits.length : cDigits.length;
      if (maxLen == 0) return 0.7;
      final similarity = 1.0 - (dist / maxLen);
      if (similarity >= 0.5) return 0.3 + (similarity * 0.4);
    }

    // General fuzzy: edit distance on full normalized strings
    final dist = _editDistance(q, c);
    final maxLen = q.length > c.length ? q.length : c.length;
    final similarity = 1.0 - (dist / maxLen);

    // Allow up to ~40% difference
    if (similarity >= 0.6) return 0.2 + (similarity * 0.3);

    return 0.0;
  }

  /// Searches [items] and returns matches sorted by relevance.
  ///
  /// [getText] extracts the searchable plate string from each item.
  /// Results with score < [threshold] are excluded.
  static List<FuzzyMatch<T>> search<T>({
    required String query,
    required Iterable<T> items,
    required String Function(T) getText,
    double threshold = 0.2,
  }) {
    if (query.trim().isEmpty) return [];

    final matches = <FuzzyMatch<T>>[];
    for (final item in items) {
      final s = score(query, getText(item));
      if (s >= threshold) {
        matches.add(FuzzyMatch(item, s));
      }
    }

    // Sort by score descending, then alphabetically for ties
    matches.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return getText(a.item).compareTo(getText(b.item));
    });

    return matches;
  }

  /// Levenshtein edit distance between two strings.
  static int _editDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final m = a.length;
    final n = b.length;

    // Use single-row optimization
    var prev = List.generate(n + 1, (i) => i);
    var curr = List.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = _min3(
          prev[j] + 1, // deletion
          curr[j - 1] + 1, // insertion
          prev[j - 1] + cost, // substitution
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[n];
  }

  static int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    if (b <= c) return b;
    return c;
  }
}
