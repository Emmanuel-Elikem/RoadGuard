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
    // Keep alphanumeric, hyphens, and spaces
    final cleaned = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9\- ]'), '')
        .toUpperCase();

    // Preserve cursor position relative to new length
    final cursorOffset = cleaned.length < newValue.selection.baseOffset
        ? cleaned.length
        : newValue.selection.baseOffset;

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, cleaned.length),
      ),
    );
  }
}
