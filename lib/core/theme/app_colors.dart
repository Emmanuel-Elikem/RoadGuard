/// RoadGuard Color System - Single source of truth for all app colors.
///
/// Supports both DARK and LIGHT modes as per the Design System.
/// Dark = "The Cockpit" (OLED-friendly, high contrast)
/// Light = "The Soft Look" (clean, professional)
library;

import 'package:flutter/material.dart';

/// Dark mode color palette - "The Cockpit"
/// Premium OLED-friendly dark theme with neon accents.
abstract final class AppColorsDark {
  // === BACKGROUNDS ===
  static const Color background = Color(0xFF000000); // True OLED black
  static const Color surface = Color(0xFF0F172A); // Deep midnight blue
  static const Color cardBackground = Color(0xFF1E293B); // Elevated cards
  static const Color surfaceVariant = Color(0xFF334155); // Highest elevation

  // === PRIMARY - Neon Volt ===
  static const Color primary = Color(0xFFCDFF00); // Electric yellow-green
  static const Color primaryMuted = Color(0x33CDFF00); // 20% opacity
  static const Color primaryContainer = Color(
    0xFF1A2E05,
  ); // Dark green container
  static const Color onPrimary = Color(0xFF000000); // Black text on primary

  // === SECONDARY - Cyber Blue ===
  static const Color secondary = Color(0xFF38BDF8); // Cool cyan blue
  static const Color secondaryContainer = Color(
    0xFF0C4A6E,
  ); // Dark blue container
  static const Color onSecondary = Color(0xFF000000); // Black text on secondary

  // === TERTIARY ===
  static const Color tertiary = Color(0xFF00FFD1); // Mint accent

  // === TEXT ===
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted gray
  static const Color textTertiary = Color(0xFF64748B); // Hint text
  static const Color textDisabled = Color(0xFF475569); // Disabled state

  // === SPEED INDICATORS ===
  static const Color speedSafe = Color(0xFF00FF88); // Green glow
  static const Color speedWarning = Color(0xFFFF9500); // Orange alert
  static const Color speedDanger = Color(0xFFFF3B30); // Red danger
  static const Color speedGlow = Color(0x20CDFF00); // Primary glow

  // === RATINGS ===
  static const Color ratingExcellent = Color(0xFF00FF88);
  static const Color ratingGood = Color(0xFF7BFF00);
  static const Color ratingAverage = Color(0xFFFFAA00);
  static const Color ratingPoor = Color(0xFFFF6B00);
  static const Color ratingTerrible = Color(0xFFFF3B30);

  // === SEMANTIC ===
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFFF3B30); // Infrared
  static const Color warning = Color(0xFFFF9500); // Alert orange
  static const Color info = Color(0xFF38BDF8); // Cyber blue

  // === BORDERS ===
  static const Color border = Color(0xFF334155); // Subtle borders
  static const Color borderFocused = Color(0xFFCDFF00); // Primary focus
  static const Color divider = Color(0xFF1E293B); // Divider lines

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Light mode color palette - "The Soft Look"
/// Clean, professional light theme.
abstract final class AppColorsLight {
  // === BACKGROUNDS ===
  static const Color background = Color(0xFFF8FAFC); // Off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Input backgrounds

  // === PRIMARY - Deep Volt ===
  static const Color primary = Color(
    0xFF65A30D,
  ); // Lime green (darker for contrast)
  static const Color primaryMuted = Color(0x3365A30D); // 20% opacity
  static const Color primaryContainer = Color(
    0xFFECFCCB,
  ); // Light green container
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary

  // === SECONDARY - Ocean Blue ===
  static const Color secondary = Color(0xFF0EA5E9); // Sky blue
  static const Color secondaryContainer = Color(
    0xFFE0F2FE,
  ); // Light blue container
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on secondary

  // === TERTIARY ===
  static const Color tertiary = Color(0xFF14B8A6); // Teal accent

  // === TEXT ===
  static const Color textPrimary = Color(0xFF0F172A); // Almost black
  static const Color textSecondary = Color(0xFF64748B); // Muted gray
  static const Color textTertiary = Color(0xFF94A3B8); // Hint text
  static const Color textDisabled = Color(0xFFCBD5E1); // Disabled state

  // === SPEED INDICATORS ===
  static const Color speedSafe = Color(0xFF22C55E); // Green
  static const Color speedWarning = Color(0xFFF59E0B); // Amber
  static const Color speedDanger = Color(0xFFEF4444); // Red
  static const Color speedGlow = Color(0x2065A30D); // Primary glow

  // === RATINGS ===
  static const Color ratingExcellent = Color(0xFF22C55E);
  static const Color ratingGood = Color(0xFF84CC16);
  static const Color ratingAverage = Color(0xFFF59E0B);
  static const Color ratingPoor = Color(0xFFF97316);
  static const Color ratingTerrible = Color(0xFFEF4444);

  // === SEMANTIC ===
  static const Color success = Color(0xFF22C55E); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF0EA5E9); // Sky blue

  // === BORDERS ===
  static const Color border = Color(0xFFE2E8F0); // Light borders
  static const Color borderFocused = Color(0xFF65A30D); // Primary focus
  static const Color divider = Color(0xFFE2E8F0); // Divider lines

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Main AppColors class - static access to dark mode colors (default).
///
/// For theme-aware colors, use `Theme.of(context).colorScheme` in widgets.
/// This class provides static constants for backward compatibility and
/// use cases where context isn't available (e.g., theme construction).
abstract final class AppColors {
  // === BACKGROUNDS ===
  static const Color background = AppColorsDark.background;
  static const Color surface = AppColorsDark.surface;
  static const Color cardBackground = AppColorsDark.cardBackground;
  static const Color surfaceVariant = AppColorsDark.surfaceVariant;

  // === PRIMARY ===
  static const Color primary = AppColorsDark.primary;
  static const Color primaryMuted = AppColorsDark.primaryMuted;
  static const Color primaryContainer = AppColorsDark.primaryContainer;
  static const Color onPrimary = AppColorsDark.onPrimary;

  // === SECONDARY ===
  static const Color secondary = AppColorsDark.secondary;
  static const Color secondaryContainer = AppColorsDark.secondaryContainer;
  static const Color onSecondary = AppColorsDark.onSecondary;

  // === TERTIARY ===
  static const Color tertiary = AppColorsDark.tertiary;

  // === TEXT ===
  static const Color textPrimary = AppColorsDark.textPrimary;
  static const Color textSecondary = AppColorsDark.textSecondary;
  static const Color textTertiary = AppColorsDark.textTertiary;
  static const Color textDisabled = AppColorsDark.textDisabled;

  // === SPEED INDICATORS ===
  static const Color speedSafe = AppColorsDark.speedSafe;
  static const Color speedWarning = AppColorsDark.speedWarning;
  static const Color speedDanger = AppColorsDark.speedDanger;
  static const Color speedGlow = AppColorsDark.speedGlow;

  // === RATINGS ===
  static const Color ratingExcellent = AppColorsDark.ratingExcellent;
  static const Color ratingGood = AppColorsDark.ratingGood;
  static const Color ratingAverage = AppColorsDark.ratingAverage;
  static const Color ratingPoor = AppColorsDark.ratingPoor;
  static const Color ratingTerrible = AppColorsDark.ratingTerrible;

  // === SEMANTIC ===
  static const Color success = AppColorsDark.success;
  static const Color error = AppColorsDark.error;
  static const Color warning = AppColorsDark.warning;
  static const Color info = AppColorsDark.info;

  // === BORDERS ===
  static const Color border = AppColorsDark.border;
  static const Color borderFocused = AppColorsDark.borderFocused;
  static const Color divider = AppColorsDark.divider;

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = AppColorsDark.primaryGradient;
  static const LinearGradient backgroundGradient =
      AppColorsDark.backgroundGradient;
}
