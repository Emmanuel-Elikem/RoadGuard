/// RoadGuard Typography System - Single source of truth for all text styles.
///
/// Provides both LIGHT text (for dark mode) and DARK text (for light mode).
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles using Inter (UI) and JetBrains Mono (numbers).
///
/// Default styles use light text (white) for dark mode.
/// *Dark suffix styles use dark text for light mode.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrains Mono';

  // ============================================================
  // DARK MODE TEXT (Light colored text on dark backgrounds)
  // ============================================================

  // === DISPLAY (Hero numbers, speedometer) ===
  static const TextStyle displayLarge = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  // === HEADLINES (Section headers) ===
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColorsDark.textPrimary,
  );

  // === TITLES (Card/item titles) ===
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  // === BODY (Content text) ===
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsDark.textSecondary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsDark.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: AppColorsDark.textTertiary,
  );

  // === LABELS (Buttons, chips) ===
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsDark.textTertiary,
  );

  // === SPECIAL ===
  static const TextStyle speedUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    height: 1.0,
    color: AppColorsDark.textTertiary,
  );

  static const TextStyle numberPlate = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    height: 1.2,
    color: AppColorsDark.textPrimary,
  );

  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
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
  static const TextStyle displayLargeDark = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle displayMediumDark = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle displaySmallDark = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: AppColorsLight.textPrimary,
  );

  // === HEADLINES ===
  static const TextStyle headlineLargeDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle headlineMediumDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle headlineSmallDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColorsLight.textPrimary,
  );

  // === TITLES ===
  static const TextStyle titleLargeDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle titleMediumDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle titleSmallDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  // === BODY ===
  static const TextStyle bodyLargeDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsLight.textSecondary,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColorsLight.textSecondary,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: AppColorsLight.textTertiary,
  );

  // === LABELS ===
  static const TextStyle labelLargeDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle labelMediumDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textPrimary,
  );

  static const TextStyle labelSmallDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColorsLight.textTertiary,
  );
}
