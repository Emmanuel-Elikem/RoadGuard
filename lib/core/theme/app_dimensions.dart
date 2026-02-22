/// RoadGuard Dimensions System - Single source of truth for spacing and sizes.
///
/// Follows Material 3 design guidelines with modern rounded corners.
library;

/// Spacing, sizes, and radius values based on 8px grid system.
abstract final class AppDimensions {
  // === SPACING (8px base) ===
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingXxxl = 64.0;

  // === BORDER RADIUS ===
  // Modern Material 3 style with generous rounding
  static const double radiusXs = 4.0; // Subtle rounding
  static const double radiusSm = 8.0; // Chips, small buttons
  static const double radiusMd = 12.0; // Standard cards
  static const double radiusLg = 16.0; // Large cards, dialogs
  static const double radiusXl = 24.0; // Bottom sheets
  static const double radiusXxl = 32.0; // Extra large containers
  static const double radiusFull = 999.0; // Pills, circular buttons

  // === ICON SIZES ===
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 56.0;

  // === COMPONENT HEIGHTS ===
  static const double iconContainerSm = 40.0;
  static const double iconContainerLg = 120.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
  static const double captureButtonSize = 72.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 80.0;
  static const double cardMinHeight = 80.0;

  /// Floating navbar height (same as in FloatingNavBar widget)
  /// Used to calculate safe padding for content below navbar
  static const double floatingNavBarHeight = 60.0;

  /// Bottom padding needed for screens with floating navbar.
  /// Calculated as: navbar height + spacing + extra buffer
  /// Ensures content is never hidden behind the floating navbar
  static const double floatingNavBarSafeArea =
      floatingNavBarHeight + spacingSm + spacingMd;

  // === SPEEDOMETER SIZES ===
  static const double speedometerSizeLg = 280.0;
  static const double speedometerSizeMd = 220.0;
  static const double speedometerSizeSm = 180.0;
  static const double speedLimitSize = 72.0;

  // === AVATAR SIZES ===
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;

  // === EMPTY STATE / SPLASH SIZES ===
  static const double emptyStateIconContainer = 100.0; // Empty state icon bg
  static const double splashLogoContainer = 120.0; // Splash screen logo bg
  static const double loadingDotSize = 8.0; // Loading animation dots
  static const double loadingDotSpacing = 4.0; // Space between loading dots
  static const double speedometerSize = 280.0; // Main speedometer widget size

  // === MISC ===
  static const double ratingStarSize = 28.0;
  static const double numberPlateWidth = 200.0;

  // === ANIMATION DURATIONS (ms) ===
  static const int animationFast = 150;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int animationExtraSlow = 800;

  // === BLUR & SHADOW ===
  static const double glassBlur = 20.0;
  static const double shadowBlur = 24.0;
  static const double glowRadius = 40.0;
  static const double elevationSm = 4.0;
  static const double elevationMd = 8.0;
  static const double elevationLg = 16.0;

  // === BREAKPOINTS ===
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;
}
