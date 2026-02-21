/// Auto-formatting for Ghana plate number input.
///
/// Uppercases text and allows hyphens/spaces as typed.
/// No longer enforces strict XX-XXXX-XX format — passengers
/// encounter many different plate styles.
library;

import 'package:flutter/services.dart';

/// Uppercases plate number input and strips invalid characters.
///
/// Keeps letters, digits, hyphens, and spaces. No length cap
/// so non-standard plates (e.g. diplomatic, military, custom)
/// can be entered freely.
class PlateNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final validChars = RegExp(r'[a-zA-Z0-9\- ]');

    // Build cleaned text and map cursor offset simultaneously — count
    // only valid characters up to the original cursor position so the
    // cursor stays in the right place after stripping invalid chars.
    final buffer = StringBuffer();
    int mappedOffset = 0;
    final origOffset = newValue.selection.baseOffset;

    for (var i = 0; i < raw.length; i++) {
      if (validChars.hasMatch(raw[i])) {
        buffer.write(raw[i].toUpperCase());
        if (i < origOffset) mappedOffset++;
      }
    }

    final cleaned = buffer.toString();

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(
        offset: mappedOffset.clamp(0, cleaned.length),
      ),
    );
  }
}
