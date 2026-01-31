/// RoadGuard Color System - Single source of truth for all app colors.
library;

import 'package:flutter/material.dart';

/// App color palette based on Neo-Modern Bento design system.
abstract final class AppColors {
  // === BACKGROUNDS ===
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color cardBackground = Color(0xFF1A1A24);
  static const Color surfaceVariant = Color(0xFF22222E);

  // === PRIMARY & ACCENTS ===
  static const Color primary = Color(0xFF00D4FF);
  static const Color primaryMuted = Color(0x3300D4FF);
  static const Color secondary = Color(0xFF7B61FF);
  static const Color tertiary = Color(0xFF00FFD1);

  // === TEXT ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C7);
  static const Color textTertiary = Color(0xFF6B6B7B);
  static const Color textDisabled = Color(0xFF4A4A5A);

  // === SPEED INDICATORS ===
  static const Color speedSafe = Color(0xFF00FF88);
  static const Color speedWarning = Color(0xFFFFAA00);
  static const Color speedDanger = Color(0xFFFF3366);
  static const Color speedGlow = Color(0x2000D4FF);

  // === RATINGS ===
  static const Color ratingExcellent = Color(0xFF00FF88);
  static const Color ratingGood = Color(0xFF7BFF00);
  static const Color ratingAverage = Color(0xFFFFAA00);
  static const Color ratingPoor = Color(0xFFFF6B00);
  static const Color ratingTerrible = Color(0xFFFF3366);

  // === SEMANTIC ===
  static const Color success = Color(0xFF00FF88);
  static const Color error = Color(0xFFFF3366);
  static const Color warning = Color(0xFFFFAA00);
  static const Color info = Color(0xFF00D4FF);

  // === BORDERS ===
  static const Color border = Color(0xFF2A2A3A);
  static const Color borderFocused = Color(0xFF00D4FF);
  static const Color divider = Color(0xFF1F1F2A);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient safeGlowGradient = RadialGradient(
    colors: [Color(0x4000FF88), Color(0x0000FF88)],
  );

  static const RadialGradient dangerGlowGradient = RadialGradient(
    colors: [Color(0x40FF3366), Color(0x00FF3366)],
  );
}
