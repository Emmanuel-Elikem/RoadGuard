/// Unit tests for PlateValidator.
///
/// Tests validation, normalization, and region detection
/// for Ghana vehicle registration plates.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/utils/plate_validator.dart';

void main() {
  group('PlateValidator.validate', () {
    group('valid plates', () {
      test('accepts standard format GR-1234-21', () {
        final result = PlateValidator.validate('GR-1234-21');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'GR-1234-21');
        expect(result.region, 'GR');
      });

      test('accepts format without separators GR123421', () {
        final result = PlateValidator.validate('GR123421');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'GR-1234-21');
      });

      test('accepts format with spaces GR 1234 21', () {
        final result = PlateValidator.validate('GR 1234 21');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'GR-1234-21');
      });

      test('accepts lowercase input', () {
        final result = PlateValidator.validate('gr-1234-21');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'GR-1234-21');
      });

      test('accepts 5-digit number', () {
        final result = PlateValidator.validate('AS-12345-20');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'AS-12345-20');
      });

      test('accepts mixed separators', () {
        final result = PlateValidator.validate('CR 1234-22');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'CR-1234-22');
      });

      test('trims whitespace', () {
        final result = PlateValidator.validate('  GR-1234-21  ');
        expect(result.isValid, isTrue);
        expect(result.formatted, 'GR-1234-21');
      });

      test('accepts year 00 (2000)', () {
        final result = PlateValidator.validate('GR-1234-00');
        expect(result.isValid, isTrue);
      });

      test('accepts year 99 (1999)', () {
        final result = PlateValidator.validate('GR-1234-99');
        expect(result.isValid, isTrue);
      });

      test('accepts year 90 (1990)', () {
        final result = PlateValidator.validate('GR-1234-90');
        expect(result.isValid, isTrue);
      });
    });

    group('valid regions', () {
      test('accepts all 22 region codes', () {
        for (final region in PlateValidator.validRegions) {
          final result = PlateValidator.validate('$region-1234-21');
          expect(result.isValid, isTrue, reason: '$region should be valid');
          expect(result.region, region);
        }
      });

      test('maps region to correct name', () {
        expect(PlateValidator.regionNames['GR'], 'Greater Accra');
        expect(PlateValidator.regionNames['AS'], 'Ashanti');
        expect(PlateValidator.regionNames['VR'], 'Volta');
      });
    });

    group('invalid plates', () {
      test('rejects empty input', () {
        final result = PlateValidator.validate('');
        expect(result.isValid, isFalse);
        expect(result.error, 'Enter a plate number');
      });

      test('rejects whitespace-only input', () {
        final result = PlateValidator.validate('   ');
        expect(result.isValid, isFalse);
        expect(result.error, 'Enter a plate number');
      });

      test('rejects invalid format', () {
        final result = PlateValidator.validate('ABCDEF');
        expect(result.isValid, isFalse);
        expect(result.error, 'Expected format: GR-1234-21');
      });

      test('rejects unknown region code', () {
        final result = PlateValidator.validate('ZZ-1234-21');
        expect(result.isValid, isFalse);
        expect(result.error, contains('Unknown region'));
      });

      test('rejects single letter region', () {
        final result = PlateValidator.validate('G-1234-21');
        expect(result.isValid, isFalse);
      });

      test('rejects 3+ letter region', () {
        final result = PlateValidator.validate('GRR-1234-21');
        expect(result.isValid, isFalse);
      });

      test('rejects fewer than 4 digits', () {
        final result = PlateValidator.validate('GR-123-21');
        expect(result.isValid, isFalse);
      });

      test('rejects more than 5 digits', () {
        final result = PlateValidator.validate('GR-123456-21');
        expect(result.isValid, isFalse);
      });

      test('rejects single digit year', () {
        final result = PlateValidator.validate('GR-1234-2');
        expect(result.isValid, isFalse);
      });

      test('rejects 3 digit year', () {
        final result = PlateValidator.validate('GR-1234-210');
        expect(result.isValid, isFalse);
      });

      test('rejects future year beyond current', () {
        // This test is dynamic based on current year
        final futureYear = (DateTime.now().year % 100) + 5;
        if (futureYear < 90) {
          final result = PlateValidator.validate(
            'GR-1234-${futureYear.toString().padLeft(2, '0')}',
          );
          expect(result.isValid, isFalse);
          expect(result.error, contains('Invalid year'));
        }
      });
    });

    group('normalization', () {
      test('normalize returns formatted plate', () {
        expect(PlateValidator.normalize('gr 1234 21'), 'GR-1234-21');
      });

      test('normalize returns null for invalid', () {
        expect(PlateValidator.normalize('invalid'), isNull);
      });
    });

    group('isValidFormat', () {
      test('returns true for valid plate', () {
        expect(PlateValidator.isValidFormat('GR-1234-21'), isTrue);
      });

      test('returns false for invalid plate', () {
        expect(PlateValidator.isValidFormat('INVALID'), isFalse);
      });
    });
  });
}
