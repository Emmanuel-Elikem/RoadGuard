/// RoadGuard Color System
/// 
/// This file defines ALL colors used in the app.
/// NEVER use Color(0xFF...) directly in widgets.
/// ALWAYS use AppColors.colorName instead.
/// 
/// WHY: Single source of truth for colors means:
/// 1. Easy to update the entire app's look
/// 2. Consistent colors across all screens
/// 3. Easier dark/light theme switching later
library;

import 'package:flutter/material.dart';

/// Main color palette for RoadGuard
/// 
/// Based on Neo-Modern Bento design system with:
/// - Deep space blue backgrounds
/// - Electric accent colors
/// - Neon indicators for speed states
abstract final class AppColors {
  // ============================================
  // BACKGROUND COLORS
  // ============================================
  
  /// Main app background - deep space blue
  /// Used for: Scaffold backgrounds, main containers
  static const Color background = Color(0xFF0A0A0F);
  
  /// Elevated surface color - slightly lighter
  /// Used for: Cards, bottom sheets, dialogs
  static const Color surface = Color(0xFF12121A);
  
  /// Card/Bento tile background
  /// Used for: Dashboard tiles, list items
  static const Color cardBackground = Color(0xFF1A1A24);
  
  /// Subtle surface for nested elements
  /// Used for: Input fields, secondary containers
  static const Color surfaceVariant = Color(0xFF22222E);

  // ============================================
  // PRIMARY & ACCENT COLORS
  // ============================================
  
  /// Primary brand color - electric blue
  /// Used for: Primary buttons, active states, links
  static const Color primary = Color(0xFF00D4FF);
  
  /// Primary color with lower opacity
  /// Used for: Hover states, backgrounds of primary elements
  static const Color primaryMuted = Color(0x3300D4FF); // 20% opacity
  
  /// Secondary accent - purple glow
  /// Used for: Secondary buttons, accents, gradients
  static const Color secondary = Color(0xFF7B61FF);
  
  /// Tertiary accent - cyan
  /// Used for: Highlights, special indicators
  static const Color tertiary = Color(0xFF00FFD1);

  // ============================================
  // TEXT COLORS
  // ============================================
  
  /// Primary text - high emphasis
  /// Used for: Headings, important content
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - medium emphasis
  /// Used for: Body text, descriptions
  static const Color textSecondary = Color(0xFFB8B8C7);
  
  /// Tertiary text - low emphasis
  /// Used for: Captions, hints, placeholders
  static const Color textTertiary = Color(0xFF6B6B7B);
  
  /// Disabled text
  /// Used for: Disabled states, inactive elements
  static const Color textDisabled = Color(0xFF4A4A5A);

  // ============================================
  // SPEED INDICATOR COLORS (Critical for UX)
  // ============================================
  
  /// Safe speed - green glow
  /// Used when: Speed is within limit
  static const Color speedSafe = Color(0xFF00FF88);
  
  /// Warning speed - amber/yellow
  /// Used when: Approaching speed limit (80-99% of limit)
  static const Color speedWarning = Color(0xFFFFAA00);
  
  /// Danger speed - red alert
  /// Used when: Exceeding speed limit
  static const Color speedDanger = Color(0xFFFF3366);
  
  /// Speed indicator background glow (for arc)
  static const Color speedGlow = Color(0x2000D4FF);

  // ============================================
  // RATING COLORS
  // ============================================
  
  /// Excellent rating (5 stars)
  static const Color ratingExcellent = Color(0xFF00FF88);
  
  /// Good rating (4 stars)
  static const Color ratingGood = Color(0xFF7BFF00);
  
  /// Average rating (3 stars)
  static const Color ratingAverage = Color(0xFFFFAA00);
  
  /// Poor rating (2 stars)
  static const Color ratingPoor = Color(0xFFFF6B00);
  
  /// Terrible rating (1 star)
  static const Color ratingTerrible = Color(0xFFFF3366);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  
  /// Success state
  static const Color success = Color(0xFF00FF88);
  
  /// Error state
  static const Color error = Color(0xFFFF3366);
  
  /// Warning state
  static const Color warning = Color(0xFFFFAA00);
  
  /// Info state
  static const Color info = Color(0xFF00D4FF);

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================
  
  /// Default border color
  static const Color border = Color(0xFF2A2A3A);
  
  /// Focused/Active border
  static const Color borderFocused = Color(0xFF00D4FF);
  
  /// Divider color
  static const Color divider = Color(0xFF1F1F2A);

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================
  
  /// Primary gradient for buttons, highlights
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Background gradient for hero sections
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// Speed safe glow gradient
  static const RadialGradient safeGlowGradient = RadialGradient(
    colors: [
      Color(0x4000FF88), // 25% opacity
      Color(0x0000FF88), // 0% opacity
    ],
  );
  
  /// Speed danger glow gradient
  static const RadialGradient dangerGlowGradient = RadialGradient(
    colors: [
      Color(0x40FF3366), // 25% opacity
      Color(0x00FF3366), // 0% opacity
    ],
  );
}
