/// RoadGuard Theme - Combines colors, typography, and dimensions into ThemeData.
///
/// Provides both DARK ("The Cockpit") and LIGHT ("The Soft Look") themes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Creates the dark theme - "The Cockpit"
/// Premium OLED-friendly dark theme with neon accents.
ThemeData createDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // === COLOR SCHEME ===
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      onPrimaryContainer: AppColorsDark.primary,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.onSecondary,
      secondaryContainer: AppColorsDark.secondaryContainer,
      onSecondaryContainer: AppColorsDark.secondary,
      tertiary: AppColorsDark.tertiary,
      onTertiary: AppColorsDark.background,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      surfaceContainerHighest: AppColorsDark.cardBackground,
      error: AppColorsDark.error,
      onError: AppColorsDark.textPrimary,
      outline: AppColorsDark.border,
      outlineVariant: AppColorsDark.divider,
    ),

    scaffoldBackgroundColor: AppColorsDark.background,

    // === APP BAR ===
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.background,
      foregroundColor: AppColorsDark.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleLarge,
      iconTheme: const IconThemeData(
        color: AppColorsDark.textPrimary,
        size: AppDimensions.iconMd,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // === CARD ===
    cardTheme: CardThemeData(
      color: AppColorsDark.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColorsDark.border, width: 1),
      ),
      margin: const EdgeInsets.all(AppDimensions.spacingSm),
    ),

    // === ELEVATED BUTTON ===
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === OUTLINED BUTTON ===
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        side: const BorderSide(color: AppColorsDark.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === TEXT BUTTON ===
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === INPUT DECORATION ===
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsDark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsDark.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsDark.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColorsDark.textTertiary,
      ),
      errorStyle: AppTypography.errorText,
    ),

    // === BOTTOM NAVIGATION ===
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColorsDark.surface,
      selectedItemColor: AppColorsDark.primary,
      unselectedItemColor: AppColorsDark.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
    ),

    // === FAB ===
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: AppColorsDark.onPrimary,
      elevation: AppDimensions.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),

    // === SNACKBAR ===
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsDark.surfaceVariant,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColorsDark.textPrimary,
      ),
      actionTextColor: AppColorsDark.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // === DIALOG ===
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsDark.surface,
      elevation: AppDimensions.elevationLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineSmall,
      contentTextStyle: AppTypography.bodyMedium,
    ),

    // === BOTTOM SHEET ===
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColorsDark.surface,
      modalBackgroundColor: AppColorsDark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
    ),

    // === DIVIDER ===
    dividerTheme: const DividerThemeData(
      color: AppColorsDark.divider,
      thickness: 1,
      space: AppDimensions.spacingMd,
    ),

    // === ICON ===
    iconTheme: const IconThemeData(
      color: AppColorsDark.textSecondary,
      size: AppDimensions.iconMd,
    ),

    // === TEXT THEME ===
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
  );
}

/// Creates the light theme - "The Soft Look"
/// Clean, professional light theme.
ThemeData createLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // === COLOR SCHEME ===
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      primaryContainer: AppColorsLight.primaryContainer,
      onPrimaryContainer: AppColorsLight.primary,
      secondary: AppColorsLight.secondary,
      onSecondary: AppColorsLight.onSecondary,
      secondaryContainer: AppColorsLight.secondaryContainer,
      onSecondaryContainer: AppColorsLight.secondary,
      tertiary: AppColorsLight.tertiary,
      onTertiary: AppColorsLight.background,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.textPrimary,
      surfaceContainerHighest: AppColorsLight.cardBackground,
      error: AppColorsLight.error,
      onError: Colors.white,
      outline: AppColorsLight.border,
      outlineVariant: AppColorsLight.divider,
    ),

    scaffoldBackgroundColor: AppColorsLight.background,

    // === APP BAR ===
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsLight.background,
      foregroundColor: AppColorsLight.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleLargeDark,
      iconTheme: const IconThemeData(
        color: AppColorsLight.textPrimary,
        size: AppDimensions.iconMd,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // === CARD ===
    cardTheme: CardThemeData(
      color: AppColorsLight.cardBackground,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      margin: const EdgeInsets.all(AppDimensions.spacingSm),
    ),

    // === ELEVATED BUTTON ===
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.primary,
        foregroundColor: AppColorsLight.onPrimary,
        elevation: 2,
        shadowColor: AppColorsLight.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === OUTLINED BUTTON ===
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsLight.primary,
        side: const BorderSide(color: AppColorsLight.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === TEXT BUTTON ===
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsLight.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // === INPUT DECORATION ===
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsLight.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsLight.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsLight.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsLight.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColorsLight.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMediumDark,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColorsLight.textTertiary,
      ),
      errorStyle: AppTypography.errorText,
    ),

    // === BOTTOM NAVIGATION ===
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColorsLight.surface,
      selectedItemColor: AppColorsLight.primary,
      unselectedItemColor: AppColorsLight.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
    ),

    // === FAB ===
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorsLight.primary,
      foregroundColor: AppColorsLight.onPrimary,
      elevation: AppDimensions.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),

    // === SNACKBAR ===
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColorsLight.textPrimary,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // === DIALOG ===
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsLight.surface,
      elevation: AppDimensions.elevationLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineSmallDark,
      contentTextStyle: AppTypography.bodyMediumDark,
    ),

    // === BOTTOM SHEET ===
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColorsLight.surface,
      modalBackgroundColor: AppColorsLight.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
    ),

    // === DIVIDER ===
    dividerTheme: const DividerThemeData(
      color: AppColorsLight.divider,
      thickness: 1,
      space: AppDimensions.spacingMd,
    ),

    // === ICON ===
    iconTheme: const IconThemeData(
      color: AppColorsLight.textSecondary,
      size: AppDimensions.iconMd,
    ),

    // === TEXT THEME (with dark colors for light mode) ===
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLargeDark,
      displayMedium: AppTypography.displayMediumDark,
      displaySmall: AppTypography.displaySmallDark,
      headlineLarge: AppTypography.headlineLargeDark,
      headlineMedium: AppTypography.headlineMediumDark,
      headlineSmall: AppTypography.headlineSmallDark,
      titleLarge: AppTypography.titleLargeDark,
      titleMedium: AppTypography.titleMediumDark,
      titleSmall: AppTypography.titleSmallDark,
      bodyLarge: AppTypography.bodyLargeDark,
      bodyMedium: AppTypography.bodyMediumDark,
      bodySmall: AppTypography.bodySmallDark,
      labelLarge: AppTypography.labelLargeDark,
      labelMedium: AppTypography.labelMediumDark,
      labelSmall: AppTypography.labelSmallDark,
    ),
  );
}

/// DEPRECATED: Use createDarkTheme() instead.
/// Kept for backwards compatibility during migration.
ThemeData createAppTheme() => createDarkTheme();
