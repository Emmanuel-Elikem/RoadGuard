/// RoadGuard Spacing & Dimensions System
/// 
/// This file defines ALL spacing, sizes, and dimensions.
/// NEVER use magic numbers like Padding(8) directly.
/// ALWAYS use AppDimensions.spacingMd instead.
/// 
/// WHY: Consistent spacing means:
/// 1. Visual rhythm and harmony
/// 2. Easy to adjust spacing app-wide
/// 3. Responsive design becomes easier
/// 
/// SPACING SCALE (8px base):
/// xs: 4px  | sm: 8px  | md: 16px | lg: 24px | xl: 32px | xxl: 48px
library;

/// All spacing, sizes, radius values for RoadGuard
/// 
/// Based on 8px grid system for visual consistency
/// 8px chosen because it:
/// - Divides evenly into common screen sizes
/// - Creates pleasing visual rhythm
/// - Industry standard (Material Design uses 8px)
abstract final class AppDimensions {
  // ============================================
  // SPACING (Padding, Margins, Gaps)
  // ============================================
  
  /// Extra small spacing (4px)
  /// Used for: Tight gaps, icon padding
  static const double spacingXs = 4.0;
  
  /// Small spacing (8px)
  /// Used for: Between related elements
  static const double spacingSm = 8.0;
  
  /// Medium spacing (16px) - DEFAULT
  /// Used for: Standard padding, most gaps
  static const double spacingMd = 16.0;
  
  /// Large spacing (24px)
  /// Used for: Section separation, card padding
  static const double spacingLg = 24.0;
  
  /// Extra large spacing (32px)
  /// Used for: Major section gaps
  static const double spacingXl = 32.0;
  
  /// Double extra large spacing (48px)
  /// Used for: Screen margins, hero sections
  static const double spacingXxl = 48.0;
  
  /// Triple extra large spacing (64px)
  /// Used for: Major layout gaps
  static const double spacingXxxl = 64.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  
  /// Small radius (8px)
  /// Used for: Buttons, chips, small cards
  static const double radiusSm = 8.0;
  
  /// Medium radius (12px)
  /// Used for: Cards, containers
  static const double radiusMd = 12.0;
  
  /// Large radius (16px)
  /// Used for: Large cards, modals
  static const double radiusLg = 16.0;
  
  /// Extra large radius (24px)
  /// Used for: Bottom sheets, hero containers
  static const double radiusXl = 24.0;
  
  /// Full/Circular radius
  /// Used for: Pills, circular buttons, avatars
  static const double radiusFull = 999.0;

  // ============================================
  // ICON SIZES
  // ============================================
  
  /// Small icon (16px)
  /// Used for: Inline icons, badges
  static const double iconSm = 16.0;
  
  /// Medium icon (24px) - DEFAULT
  /// Used for: Most UI icons
  static const double iconMd = 24.0;
  
  /// Large icon (32px)
  /// Used for: Prominent icons, nav items
  static const double iconLg = 32.0;
  
  /// Extra large icon (48px)
  /// Used for: Feature icons, empty states
  static const double iconXl = 48.0;

  // ============================================
  // COMPONENT HEIGHTS
  // ============================================
  
  /// Button height - small (36px)
  static const double buttonHeightSm = 36.0;
  
  /// Button height - medium (48px) - DEFAULT
  static const double buttonHeightMd = 48.0;
  
  /// Button height - large (56px)
  static const double buttonHeightLg = 56.0;
  
  /// Input field height (56px)
  static const double inputHeight = 56.0;
  
  /// App bar height (64px)
  static const double appBarHeight = 64.0;
  
  /// Bottom navigation height (80px)
  static const double bottomNavHeight = 80.0;
  
  /// Card minimum height (80px)
  static const double cardMinHeight = 80.0;

  // ============================================
  // SPECIFIC COMPONENT SIZES
  // ============================================
  
  /// Speedometer dial size (large screens)
  static const double speedometerSizeLg = 280.0;
  
  /// Speedometer dial size (medium screens)
  static const double speedometerSizeMd = 220.0;
  
  /// Speedometer dial size (small screens)
  static const double speedometerSizeSm = 180.0;
  
  /// Speed limit indicator size
  static const double speedLimitSize = 72.0;
  
  /// Avatar size - small (32px)
  static const double avatarSm = 32.0;
  
  /// Avatar size - medium (48px)
  static const double avatarMd = 48.0;
  
  /// Avatar size - large (64px)
  static const double avatarLg = 64.0;
  
  /// Rating star size
  static const double ratingStarSize = 28.0;
  
  /// Number plate display width
  static const double numberPlateWidth = 200.0;

  // ============================================
  // ANIMATION DURATIONS (milliseconds)
  // ============================================
  
  /// Fast animation (150ms)
  /// Used for: Micro-interactions, hover states
  static const int animationFast = 150;
  
  /// Normal animation (300ms) - DEFAULT
  /// Used for: Most transitions
  static const int animationNormal = 300;
  
  /// Slow animation (500ms)
  /// Used for: Page transitions, complex animations
  static const int animationSlow = 500;
  
  /// Extra slow animation (800ms)
  /// Used for: Dramatic reveals, onboarding
  static const int animationExtraSlow = 800;

  // ============================================
  // BLUR & SHADOW VALUES
  // ============================================
  
  /// Glass effect blur radius
  static const double glassBlur = 20.0;
  
  /// Card shadow blur
  static const double shadowBlur = 24.0;
  
  /// Glow effect radius (for speed states)
  static const double glowRadius = 40.0;
  
  /// Elevation - small (4)
  static const double elevationSm = 4.0;
  
  /// Elevation - medium (8)
  static const double elevationMd = 8.0;
  
  /// Elevation - large (16)
  static const double elevationLg = 16.0;

  // ============================================
  // BREAKPOINTS (for responsive design)
  // ============================================
  
  /// Mobile breakpoint max width
  static const double breakpointMobile = 600.0;
  
  /// Tablet breakpoint max width
  static const double breakpointTablet = 900.0;
  
  /// Desktop breakpoint (above tablet)
  static const double breakpointDesktop = 1200.0;
}
