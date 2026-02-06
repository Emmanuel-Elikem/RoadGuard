/// RoadGuard Typography System - Single source of truth for all text styles.
///
/// Uses Google Fonts for consistent typography across all devices:
/// - Poppins: Primary UI font (geometric, modern, friendly)
/// - JetBrains Mono: Monospace for numbers/speedometer
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles using Poppins (UI) and JetBrains Mono (numbers).
///
/// Poppins weights used:
/// - w900: Black (hero headlines)
/// - w700: Bold (headlines)
/// - w600: SemiBold (titles)
/// - w500: Medium (labels, buttons)
/// - w400: Regular (body text)
///
/// Default styles use light text (white) for dark mode.
/// *Dark suffix styles use dark text for light mode.
abstract final class AppTypography {
  // Font family getters using Google Fonts
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  static String get monoFontFamily => GoogleFonts.jetBrainsMono().fontFamily!;

  // ============================================================
  // DARK MODE TEXT (Light colored text on dark backgrounds)
  // ============================================================

  // === DISPLAY (Hero numbers, speedometer) ===
  static TextStyle get displayLarge => GoogleFonts.jetBrainsMono(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
        height: 1.0,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        height: 1.2,
        color: AppColorsDark.textPrimary,
      );

  // === HEADLINES (Section headers) ===
  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColorsDark.textPrimary,
      );

  // === TITLES (Card/item titles) ===
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColorsDark.textPrimary,
      );

  // === BODY (Content text) ===
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColorsDark.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColorsDark.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColorsDark.textTertiary,
      );

  // === LABELS (Buttons, chips) ===
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsDark.textTertiary,
      );

  // === SPECIAL ===
  static TextStyle get speedUnit => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        height: 1.0,
        color: AppColorsDark.textTertiary,
      );

  static TextStyle get numberPlate => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        height: 1.2,
        color: AppColorsDark.textPrimary,
      );

  static TextStyle get errorText => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.4,
        color: AppColorsDark.error,
      );

  // ============================================================
  // LIGHT MODE TEXT (Dark colored text on light backgrounds)
  // ============================================================

  // === DISPLAY ===
  static TextStyle get displayLargeDark => GoogleFonts.jetBrainsMono(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
        height: 1.0,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get displayMediumDark => GoogleFonts.jetBrainsMono(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get displaySmallDark => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        height: 1.2,
        color: AppColorsLight.textPrimary,
      );

  // === HEADLINES ===
  static TextStyle get headlineLargeDark => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get headlineMediumDark => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get headlineSmallDark => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColorsLight.textPrimary,
      );

  // === TITLES ===
  static TextStyle get titleLargeDark => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get titleMediumDark => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get titleSmallDark => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColorsLight.textPrimary,
      );

  // === BODY ===
  static TextStyle get bodyLargeDark => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColorsLight.textSecondary,
      );

  static TextStyle get bodyMediumDark => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColorsLight.textSecondary,
      );

  static TextStyle get bodySmallDark => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColorsLight.textTertiary,
      );

  // === LABELS ===
  static TextStyle get labelLargeDark => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get labelMediumDark => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsLight.textPrimary,
      );

  static TextStyle get labelSmallDark => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: AppColorsLight.textTertiary,
      );
}
