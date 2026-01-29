/// RoadGuard Typography System
/// 
/// This file defines ALL text styles used in the app.
/// NEVER create TextStyle() directly in widgets.
/// ALWAYS use AppTypography.styleName instead.
/// 
/// WHY: Consistent typography means:
/// 1. Professional, cohesive look
/// 2. Easy to change fonts app-wide
/// 3. Proper hierarchy guides user attention
/// 
/// NAMING CONVENTION:
/// - display: Large hero text (speed numbers)
/// - headline: Section headers
/// - title: Card titles, screen titles
/// - body: Regular content
/// - label: Buttons, tags, small text
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography styles for RoadGuard
/// 
/// Uses Inter font family (clean, modern, highly legible)
/// Falls back to system fonts if Inter not loaded
abstract final class AppTypography {
  /// Base font family
  /// Inter is chosen for:
  /// - Excellent legibility at all sizes
  /// - Modern, clean aesthetic
  /// - Great number rendering (important for speedometer)
  static const String fontFamily = 'Inter';
  
  /// Monospace font for numbers (speedometer, stats)
  /// JetBrains Mono is chosen for:
  /// - Equal-width digits (numbers don't "jump")
  /// - Clear distinction between similar characters
  static const String monoFontFamily = 'JetBrains Mono';

  // ============================================
  // DISPLAY STYLES (Hero numbers, speedometer)
  // ============================================
  
  /// Massive speed display (72px)
  /// Used for: Main speedometer number
  static const TextStyle displayLarge = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
    color: AppColors.textPrimary,
  );
  
  /// Large display text (48px)
  /// Used for: Secondary stats, large callouts
  static const TextStyle displayMedium = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );
  
  /// Medium display text (36px)
  /// Used for: Rating scores, important numbers
  static const TextStyle displaySmall = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ============================================
  // HEADLINE STYLES (Section headers)
  // ============================================
  
  /// Large headline (32px)
  /// Used for: Screen titles, major sections
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  /// Medium headline (24px)
  /// Used for: Card headers, subsection titles
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  
  /// Small headline (20px)
  /// Used for: List headers, dialog titles
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ============================================
  // TITLE STYLES (Item titles)
  // ============================================
  
  /// Large title (18px semibold)
  /// Used for: Card titles, emphasized items
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  /// Medium title (16px semibold)
  /// Used for: List item titles, button text
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  /// Small title (14px semibold)
  /// Used for: Small card titles, labels
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ============================================
  // BODY STYLES (Content text)
  // ============================================
  
  /// Large body text (16px regular)
  /// Used for: Main content, descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  /// Medium body text (14px regular)
  /// Used for: Secondary content, form fields
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  /// Small body text (12px regular)
  /// Used for: Captions, metadata
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.5,
    color: AppColors.textTertiary,
  );

  // ============================================
  // LABEL STYLES (Buttons, chips, tags)
  // ============================================
  
  /// Large label (14px medium)
  /// Used for: Primary buttons, navigation items
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  /// Medium label (12px medium)
  /// Used for: Secondary buttons, chips
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  /// Small label (10px medium)
  /// Used for: Badges, tiny indicators
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================
  
  /// Speed unit text (km/h)
  /// Used for: Unit labels next to speed
  static const TextStyle speedUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    height: 1.0,
    color: AppColors.textTertiary,
  );
  
  /// Number plate style (bold, monospace)
  /// Used for: Vehicle plate number display
  static const TextStyle numberPlate = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  /// Error/validation message
  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: AppColors.error,
  );
}
