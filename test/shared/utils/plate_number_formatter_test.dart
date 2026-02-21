/// Unit tests for PlateNumberFormatter.
///
/// Tests uppercasing and character filtering
/// for plate number input.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/utils/plate_number_formatter.dart';

void main() {
  late PlateNumberFormatter formatter;

  setUp(() {
    formatter = PlateNumberFormatter();
  });

  TextEditingValue format(String text, {int? cursor}) {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    );
    return formatter.formatEditUpdate(TextEditingValue.empty, value);
  }

  group('PlateNumberFormatter', () {
    test('uppercases input', () {
      final result = format('gr');
      expect(result.text, 'GR');
    });

    test('preserves hyphens typed by user', () {
      final result = format('GR-1234-21');
      expect(result.text, 'GR-1234-21');
    });

    test('preserves spaces typed by user', () {
      final result = format('GR 1234 21');
      expect(result.text, 'GR 1234 21');
    });

    test('does not cap input length', () {
      final result = format('ABC-12345-XY99');
      expect(result.text, 'ABC-12345-XY99');
    });

    test('handles empty input', () {
      final result = format('');
      expect(result.text, '');
    });

    test('handles short input', () {
      final result = format('GR');
      expect(result.text, 'GR');
    });

    test('strips special characters except hyphens and spaces', () {
      final result = format('G@R#1!2');
      expect(result.text, 'GR12');
    });

    test('allows long non-standard plate number', () {
      final result = format('GV 1234 ABCDE');
      expect(result.text, 'GV 1234 ABCDE');
    });

    test('cursor position stays within text bounds', () {
      final result = format('GR-12', cursor: 5);
      expect(result.selection.baseOffset, 5);
    });

    test('cursor adjusts when invalid chars are removed before it', () {
      // Typing G@R with cursor after @ (position 2)
      // Should strip @, cursor should land after G (position 1)
      final result = format('G@R', cursor: 2);
      expect(result.text, 'GR');
      expect(result.selection.baseOffset, 1);
    });

    test('cursor correct when multiple invalid chars removed', () {
      // 'A#B!C' with cursor at end (pos 5)
      // Cleaned: 'ABC', cursor mapped: 3
      final result = format('A#B!C', cursor: 5);
      expect(result.text, 'ABC');
      expect(result.selection.baseOffset, 3);
    });
  });
}
