/// Unit tests for PlateNumberFormatter.
///
/// Tests auto-hyphen insertion and cursor positioning
/// for Ghana plate number input.
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

    test('inserts first hyphen after 2 letters', () {
      final result = format('GR1');
      expect(result.text, 'GR-1');
    });

    test('formats full plate correctly', () {
      final result = format('GR123421');
      expect(result.text, 'GR-1234-21');
    });

    test('handles existing hyphens (strips and reformats)', () {
      final result = format('GR-1234-21');
      expect(result.text, 'GR-1234-21');
    });

    test('handles spaces (strips and reformats)', () {
      final result = format('GR 1234 21');
      expect(result.text, 'GR-1234-21');
    });

    test('caps at 8 raw characters', () {
      final result = format('GR12342199');
      expect(result.text, 'GR-1234-21');
    });

    test('handles empty input', () {
      final result = format('');
      expect(result.text, '');
    });

    test('handles just region code', () {
      final result = format('GR');
      expect(result.text, 'GR');
    });

    test('no second hyphen when fewer than 7 raw chars', () {
      final result = format('GR1234');
      expect(result.text, 'GR-1234');
      expect(result.text.indexOf('-'), 2);
      expect(result.text.lastIndexOf('-'), 2);
    });

    test('second hyphen appears at 7th raw char', () {
      final result = format('GR12342');
      expect(result.text, 'GR-1234-2');
    });

    test('cursor follows raw character count', () {
      final result = format('GR1', cursor: 3);
      // 3 raw chars typed → cursor at position 4 (after 'GR-1')
      expect(result.selection.baseOffset, 4);
    });

    test('strips special characters', () {
      final result = format('G@R#1!2');
      expect(result.text, 'GR-12');
    });
  });
}
