/// RoadGuard Theme Configuration
/// 
/// This file creates the complete Flutter ThemeData
/// by combining our colors, typography, and dimensions.
/// 
/// WHY separate theme file:
/// 1. Single place to configure Material components
/// 2. Overrides default Flutter styling to match our design
/// 3. Easy to add dark/light theme switching later
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

/// Creates the complete app theme
/// 
/// This function returns a ThemeData that:
/// - Uses our custom colors throughout
/// - Applies our typography to all text
/// - Customizes all Material components
/// 
/// TEACHING NOTE:
/// ThemeData is Flutter's way of applying consistent
/// styling across the entire app. When you use 
/// Theme.of(context).colorScheme.primary, it gets
/// the value we define here.
ThemeData createAppTheme() {
  return ThemeData(
    // Use Material 3 design system
    useMaterial3: true,
    
    // Brightness affects system UI (status bar, etc.)
    brightness: Brightness.dark,
    
    // ==========================================
    // COLOR SCHEME
    // ==========================================
    colorScheme: const ColorScheme.dark(
      // Primary colors
      primary: AppColors.primary,
      onPrimary: AppColors.background, // Text ON primary
      primaryContainer: AppColors.primaryMuted,
      onPrimaryContainer: AppColors.primary,
      
      // Secondary colors
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.surfaceVariant,
      onSecondaryContainer: AppColors.secondary,
      
      // Tertiary colors
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.background,
      
      // Background & Surface
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.cardBackground,
      
      // Error colors
      error: AppColors.error,
      onError: AppColors.textPrimary,
      
      // Outline colors
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    ),
    
    // ==========================================
    // SCAFFOLD (Main background)
    // ==========================================
    scaffoldBackgroundColor: AppColors.background,
    
    // ==========================================
    // APP BAR THEME
    // ==========================================
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleLarge,
      iconTheme: IconThemeData(
        color: AppColors.textPrimary,
        size: AppDimensions.iconMd,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    
    // ==========================================
    // CARD THEME
    // ==========================================
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(AppDimensions.spacingSm),
    ),
    
    // ==========================================
    // ELEVATED BUTTON THEME
    // ==========================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
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
    
    // ==========================================
    // OUTLINED BUTTON THEME
    // ==========================================
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
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
    
    // ==========================================
    // TEXT BUTTON THEME
    // ==========================================
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    
    // ==========================================
    // INPUT DECORATION THEME (Text fields)
    // ==========================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      errorStyle: AppTypography.errorText,
    ),
    
    // ==========================================
    // BOTTOM NAVIGATION BAR THEME
    // ==========================================
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
    ),
    
    // ==========================================
    // FLOATING ACTION BUTTON THEME
    // ==========================================
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.background,
      elevation: AppDimensions.elevationMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    ),
    
    // ==========================================
    // SNACK BAR THEME
    // ==========================================
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardBackground,
      contentTextStyle: AppTypography.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // ==========================================
    // DIALOG THEME
    // ==========================================
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppDimensions.elevationLg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      titleTextStyle: AppTypography.headlineSmall,
      contentTextStyle: AppTypography.bodyMedium,
    ),
    
    // ==========================================
    // BOTTOM SHEET THEME
    // ==========================================
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
    ),
    
    // ==========================================
    // DIVIDER THEME
    // ==========================================
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: AppDimensions.spacingMd,
    ),
    
    // ==========================================
    // ICON THEME
    // ==========================================
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppDimensions.iconMd,
    ),
    
    // ==========================================
    // TEXT THEME
    // ==========================================
    textTheme: const TextTheme(
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
