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
///
/// Uses `late final` to cache TextStyle objects for better performance.
abstract final class AppTypography {
  // Font family getters using Google Fonts (cached)
  static final String fontFamily = GoogleFonts.poppins().fontFamily!;
  static final String monoFontFamily = GoogleFonts.jetBrainsMono().fontFamily!;

  // ============================================================
  // DARK MODE TEXT (Light colored text on dark backgrounds)
  // ============================================================

  // === DISPLAY (Hero numbers, speedometer) ===
  static final TextStyle displayLarge = GoogleFonts.jetBrainsMono(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle displayMedium = GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle displaySmall = GoogleFonts.jetBrainsMono(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  // === HEADLINES (Section headers) ===
  static final TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColorsDark.textPrimary,
  );

  // === TITLES (Card/item titles) ===
  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  // === BODY (Content text) ===
  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsDark.textSecondary,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsDark.textSecondary,
  );

  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: AppColorsDark.textTertiary,
  );

  // === LABELS (Buttons, chips) ===
  static final TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textTertiary,
  );

  // === SPECIAL ===
  static final TextStyle speedUnit = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    height: 1.0,
    color: AppColorsDark.textTertiary,
  );

  static final TextStyle numberPlate = GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  static final TextStyle errorText = GoogleFonts.poppins(
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
  static final TextStyle displayLargeDark = GoogleFonts.jetBrainsMono(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle displayMediumDark = GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle displaySmallDark = GoogleFonts.jetBrainsMono(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: AppColorsLight.textPrimary,
  );

  // === HEADLINES ===
  static final TextStyle headlineLargeDark = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle headlineMediumDark = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle headlineSmallDark = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColorsLight.textPrimary,
  );

  // === TITLES ===
  static final TextStyle titleLargeDark = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle titleMediumDark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle titleSmallDark = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  // === BODY ===
  static final TextStyle bodyLargeDark = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsLight.textSecondary,
  );

  static final TextStyle bodyMediumDark = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsLight.textSecondary,
  );

  static final TextStyle bodySmallDark = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: AppColorsLight.textTertiary,
  );

  // === LABELS ===
  static final TextStyle labelLargeDark = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle labelMediumDark = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static final TextStyle labelSmallDark = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textTertiary,
  );
}
