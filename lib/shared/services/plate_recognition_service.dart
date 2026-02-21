/// Plate Recognition Service — Extracts Ghana vehicle plates from OCR text.
///
/// Takes raw OCR results and identifies text that matches Ghana plate
/// patterns. Handles noisy OCR output with fuzzy matching.
library;

import 'package:road_guard/shared/services/ocr_service.dart';
import 'package:road_guard/shared/utils/plate_validator.dart';

/// A candidate plate extracted from OCR with a confidence indicator.
class PlateCandidate {
  /// The normalized plate number (e.g., "GR-1234-24").
  final String plateNumber;

  /// The raw text that was matched before normalization.
  final String rawText;

  /// How confident we are this is correct (0.0 to 1.0).
  final double confidence;

  const PlateCandidate({
    required this.plateNumber,
    required this.rawText,
    required this.confidence,
  });

  @override
  String toString() => 'PlateCandidate($plateNumber, raw: $rawText, '
      'confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Extracts Ghana vehicle plate numbers from OCR results.
///
/// Handles common OCR misreads:
/// - O/0 confusion (letter O vs digit 0)
/// - I/1 confusion (letter I vs digit 1)
/// - S/5 confusion
/// - B/8 confusion
class PlateRecognitionService {
  /// Common OCR character substitutions for digits.
  static const _digitFixes = {
    'O': '0',
    'o': '0',
    'I': '1',
    'l': '1',
    'S': '5',
    'B': '8',
    'Z': '2',
    'G': '6',
  };

  /// Common OCR character substitutions for letters.
  static const _letterFixes = {
    '0': 'O',
    '1': 'I',
    '5': 'S',
    '8': 'B',
    '2': 'Z',
    '6': 'G',
  };

  /// Extract plate candidates from OCR results.
  ///
  /// Returns candidates sorted by confidence (best first).
  List<PlateCandidate> extractPlates(OcrResult ocrResult) {
    final candidates = <PlateCandidate>[];

    // Try each text line individually
    for (final block in ocrResult.blocks) {
      for (final line in block.lines) {
        final lineCandidates = _tryExtractFromText(line.text);
        candidates.addAll(lineCandidates);

        // Also try individual elements within the line
        // (OCR might split plate into separate elements)
        if (line.elements.length >= 2) {
          final combined = line.elements.join('');
          candidates.addAll(_tryExtractFromText(combined));
        }
      }

      // Try the full block text (plate might span lines)
      final blockCandidates = _tryExtractFromText(block.text);
      candidates.addAll(blockCandidates);
    }

    // Also try the full OCR text
    candidates.addAll(_tryExtractFromText(ocrResult.fullText));

    // Deduplicate by normalized plate number, keeping highest confidence
    final seen = <String, PlateCandidate>{};
    for (final c in candidates) {
      final existing = seen[c.plateNumber];
      if (existing == null || c.confidence > existing.confidence) {
        seen[c.plateNumber] = c;
      }
    }

    final results = seen.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return results;
  }

  /// Try to extract plate numbers from a text string.
  List<PlateCandidate> _tryExtractFromText(String text) {
    final candidates = <PlateCandidate>[];

    // Clean the text: remove newlines, excess spaces
    final cleaned = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();

    if (cleaned.isEmpty) return candidates;

    // Strategy 1: Direct validation (text already looks like a plate)
    final directResult = PlateValidator.validate(cleaned);
    if (directResult.isValid) {
      candidates.add(PlateCandidate(
        plateNumber: directResult.formatted!,
        rawText: text,
        confidence: 1.0,
      ));
      return candidates;
    }

    // Strategy 2: Find plate-like patterns within the text
    // Ghana plates: 2 letters, 1-4 digits, 2 alphanumeric
    final platePattern = RegExp(
      r'([A-Z]{2})\s*[-\s]?\s*(\d{1,4})\s*[-\s]?\s*([A-Z0-9]{2})',
    );

    for (final match in platePattern.allMatches(cleaned)) {
      final raw = match.group(0)!;
      final candidate = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      final result = PlateValidator.validate(candidate);
      if (result.isValid) {
        candidates.add(PlateCandidate(
          plateNumber: result.formatted!,
          rawText: raw,
          confidence: 0.9,
        ));
      }
    }

    // Strategy 3: Apply OCR error corrections and retry
    if (candidates.isEmpty) {
      final corrected = _applyOcrCorrections(cleaned);
      for (final variant in corrected) {
        for (final match in platePattern.allMatches(variant)) {
          final raw = match.group(0)!;
          final candidate =
              '${match.group(1)}-${match.group(2)}-${match.group(3)}';
          final result = PlateValidator.validate(candidate);
          if (result.isValid) {
            candidates.add(PlateCandidate(
              plateNumber: result.formatted!,
              rawText: raw,
              confidence: 0.7,
            ));
          }
        }
      }
    }

    return candidates;
  }

  /// Generate variants of the text with common OCR fixes applied.
  List<String> _applyOcrCorrections(String text) {
    final variants = <String>[];

    // Fix digits in letter positions (first 2 chars)
    if (text.length >= 2) {
      var fixed = text;
      for (var i = 0; i < 2 && i < fixed.length; i++) {
        final char = fixed[i];
        if (_letterFixes.containsKey(char)) {
          fixed = fixed.substring(0, i) +
              _letterFixes[char]! +
              fixed.substring(i + 1);
        }
      }
      if (fixed != text) variants.add(fixed);
    }

    // Fix letters in digit positions (middle section)
    if (text.length >= 4) {
      var fixed = text;
      // Start from position 2 (after region code)
      for (var i = 2; i < fixed.length; i++) {
        final char = fixed[i];
        if (_digitFixes.containsKey(char)) {
          fixed = fixed.substring(0, i) +
              _digitFixes[char]! +
              fixed.substring(i + 1);
        }
      }
      if (fixed != text) variants.add(fixed);
    }

    return variants;
  }
}
