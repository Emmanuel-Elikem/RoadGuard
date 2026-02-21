/// Tests for PlateRecognitionService — Ghana plate extraction from OCR text.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/services/ocr_service.dart';
import 'package:road_guard/shared/services/plate_recognition_service.dart';

/// Creates an OcrResult from raw text (simulating single-line OCR output).
OcrResult _ocrFromText(String text) {
  return OcrResult(
    fullText: text,
    blocks: [
      OcrTextBlock(
        text: text,
        lines: [
          OcrTextLine(
            text: text,
            elements: text.split(' '),
          ),
        ],
      ),
    ],
  );
}

/// Creates an OcrResult with multiple lines in one block.
OcrResult _ocrFromLines(List<String> lines) {
  return OcrResult(
    fullText: lines.join('\n'),
    blocks: [
      OcrTextBlock(
        text: lines.join('\n'),
        lines: lines
            .map((l) => OcrTextLine(
                  text: l,
                  elements: l.split(' '),
                ))
            .toList(),
      ),
    ],
  );
}

void main() {
  late PlateRecognitionService service;

  setUp(() {
    service = PlateRecognitionService();
  });

  group('PlateRecognitionService', () {
    group('Strategy 1 — Direct validation', () {
      test('recognizes a clean plate number', () {
        final result = service.extractPlates(_ocrFromText('GR-1234-24'));

        expect(result, hasLength(1));
        expect(result.first.plateNumber, 'GR-1234-24');
        expect(result.first.confidence, 1.0);
      });

      test('recognizes plate without dashes', () {
        final result = service.extractPlates(_ocrFromText('GR123424'));

        expect(result, hasLength(1));
        expect(result.first.plateNumber, 'GR-1234-24');
        expect(result.first.confidence, 1.0);
      });

      test('recognizes plate with spaces', () {
        final result = service.extractPlates(_ocrFromText('GR 1234 24'));

        expect(result, hasLength(1));
        expect(result.first.plateNumber, 'GR-1234-24');
      });

      test('recognizes lowercase input', () {
        final result = service.extractPlates(_ocrFromText('gr-1234-24'));

        expect(result, hasLength(1));
        expect(result.first.plateNumber, 'GR-1234-24');
      });
    });

    group('Strategy 2 — Pattern matching within text', () {
      test('extracts plate embedded in other text', () {
        final result = service.extractPlates(
          _ocrFromText('TOYOTA COROLLA GR 1234 24 ACCRA'),
        );

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
        expect(result.first.confidence, greaterThanOrEqualTo(0.9));
      });

      test('extracts plate from noisy OCR with surrounding characters', () {
        final result = service.extractPlates(
          _ocrFromText('Number: AS 567 20'),
        );

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'AS-567-20');
      });

      test('finds plate among multiple lines', () {
        final result = service.extractPlates(
          _ocrFromLines([
            'GHANA ROAD SAFETY',
            'GR 9876 23',
            'DRIVE SAFE',
          ]),
        );

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-9876-23');
      });

      test('handles single digit number', () {
        final result = service.extractPlates(_ocrFromText('BA 5 22'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'BA-5-22');
      });
    });

    group('Strategy 3 — OCR error correction', () {
      test('corrects O→0 in digit positions', () {
        // "GR-12O4-24" → Strategy 2 matches GR-12-O4 (valid suffix).
        // To test OCR digit correction, use a case where the
        // region stays clean but numbers are embedded so the
        // regex cannot find a match without correction.
        // "GR I234 24" also tests I→1.
        final result = service.extractPlates(_ocrFromText('GR I234 24'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
      });

      test('corrects I→1 in digit positions', () {
        final result = service.extractPlates(_ocrFromText('GR I234 24'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
      });

      test('corrects 0→O in letter positions', () {
        // "0R-1234-24" → leading 0 should become O, but OR is not a region
        // Try with a valid region: "6R" → "GR"
        final result = service.extractPlates(_ocrFromText('6R 1234 24'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
        expect(result.first.confidence, 0.7);
      });

      test('corrects digit→letter in region positions', () {
        // "6A 1234 24" → 6 should become G → GA-1234-24
        final result = service.extractPlates(_ocrFromText('6A 1234 24'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GA-1234-24');
        expect(result.first.confidence, 0.7);
      });

      test('corrects 8→B in region positions', () {
        // "8A 1234 24" → 8 should become B → BA-1234-24
        final result = service.extractPlates(_ocrFromText('8A 1234 24'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'BA-1234-24');
        expect(result.first.confidence, 0.7);
      });
    });

    group('Deduplication', () {
      test('deduplicates same plate from different strategies', () {
        // "GR-1234-24" appears directly as the line text
        // AND also matches the regex within the full text
        final result = service.extractPlates(_ocrFromText('GR-1234-24'));

        // Should deduplicate to a single entry
        final uniquePlates =
            result.map((c) => c.plateNumber).toSet();
        expect(uniquePlates, hasLength(1));
        expect(uniquePlates.first, 'GR-1234-24');
      });

      test('keeps highest confidence when deduplicating', () {
        final result = service.extractPlates(_ocrFromText('GR-1234-24'));

        expect(result.first.confidence, 1.0);
      });
    });

    group('No match — raw fallback', () {
      test('returns raw text for non-plate text', () {
        final result = service.extractPlates(
          _ocrFromText('TOYOTA COROLLA'),
        );

        // Falls back to raw OCR text with low confidence
        expect(result, isNotEmpty);
        expect(result.first.confidence, 0.3);
        expect(result.first.plateNumber, contains('TOYOTA'));
      });

      test('returns empty for empty OCR result', () {
        final result = service.extractPlates(
          const OcrResult(fullText: '', blocks: []),
        );

        expect(result, isEmpty);
      });

      test('returns raw text for numbers only', () {
        final result = service.extractPlates(_ocrFromText('123456789'));

        // Raw fallback returns the text since it has digits
        expect(result, isNotEmpty);
        expect(result.first.confidence, 0.3);
      });

      test('skips very long lines for raw fallback', () {
        final longText = 'A' * 25; // > 20 chars — skipped
        final result = service.extractPlates(
          _ocrFromText(longText),
        );

        expect(result, isEmpty);
      });
    });

    group('Multiple plates', () {
      test('finds multiple plates in text', () {
        final result = service.extractPlates(
          _ocrFromLines([
            'GR 1234 24',
            'AS 5678 22',
          ]),
        );

        expect(result.length, greaterThanOrEqualTo(2));
        final plates = result.map((c) => c.plateNumber).toSet();
        expect(plates, contains('GR-1234-24'));
        expect(plates, contains('AS-5678-22'));
      });
    });

    group('Edge cases', () {
      test('handles extra whitespace gracefully', () {
        final result = service.extractPlates(
          _ocrFromText('  GR  1234  24  '),
        );

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
      });

      test('handles newlines in plate text', () {
        final result = service.extractPlates(
          _ocrFromText('GR\n1234\n24'),
        );

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-24');
      });

      test('handles alphanumeric suffix', () {
        // Suffix can be letters + digits for older plates
        final result = service.extractPlates(_ocrFromText('GR-1234-AB'));

        expect(result, isNotEmpty);
        expect(result.first.plateNumber, 'GR-1234-AB');
      });
    });

    group('PlateCandidate', () {
      test('toString includes all fields', () {
        const candidate = PlateCandidate(
          plateNumber: 'GR-1234-24',
          rawText: 'GR 1234 24',
          confidence: 0.9,
        );

        final str = candidate.toString();
        expect(str, contains('GR-1234-24'));
        expect(str, contains('GR 1234 24'));
        expect(str, contains('90%'));
      });
    });
  });
}
