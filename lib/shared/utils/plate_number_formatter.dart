/// Auto-formatting for Ghana plate number input.
///
/// Inserts hyphens as the user types: XX-XXXX-XX.
library;

import 'package:flutter/services.dart';

/// Formats plate number input with auto-inserted hyphens.
///
/// Assumes the common Ghana format: XX-NNNN-YY
/// (2-letter region, up to 4-digit number, 2-digit year).
/// Strips non-alphanumeric chars, uppercases, and caps at 8 raw characters.
class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw =
        newValue.text
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toUpperCase();

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Max 8 raw chars: 2 region + 4 number + 2 suffix
    final capped = raw.length > 8 ? raw.substring(0, 8) : raw;

    final buffer = StringBuffer();
    for (int i = 0; i < capped.length; i++) {
      if (i == 2) buffer.write('-');
      if (i == 6) buffer.write('-');
      buffer.write(capped[i]);
    }

    final formatted = buffer.toString();

    final rawBeforeCursor = _countRawChars(
      newValue.text,
      newValue.selection.baseOffset,
    );
    final cursorPos = _rawToFormattedOffset(formatted, rawBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }

  int _countRawChars(String text, int upTo) {
    int count = 0;
    for (int i = 0; i < upTo && i < text.length; i++) {
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(text[i])) count++;
    }
    return count;
  }

  int _rawToFormattedOffset(String formatted, int rawCount) {
    int raw = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (raw >= rawCount) return i;
      if (formatted[i] != '-') raw++;
    }
    return formatted.length;
  }
}
