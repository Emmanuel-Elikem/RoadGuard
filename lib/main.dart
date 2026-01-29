/// RoadGuard - Your Digital Copilot for Road Safety
/// 
/// This is the entry point of the application.
/// 
/// WHAT this file does:
/// 1. Initializes Flutter engine
/// 2. Sets up Riverpod for state management
/// 3. Creates the root App widget
/// 
/// WHY we structure it this way:
/// - ProviderScope wraps the entire app for Riverpod state
/// - App widget is separate for testing (can test without main())
/// - Uses our custom theme for consistent styling
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';

/// Application entry point
/// 
/// TEACHING NOTE:
/// main() is where Dart starts executing your code.
/// Everything Flutter does begins here.
void main() {
  // Ensure Flutter is initialized before we do anything else
  // This is required when calling platform code before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait mode
  // WHY: Speedometer UI is designed for portrait. Landscape would require
  // a complete redesign. Most driving apps are portrait-only.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style (status bar, navigation bar)
  // This makes the status bar icons light (white) on our dark background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Run the app wrapped in ProviderScope
  // 
  // TEACHING NOTE on ProviderScope:
  // Riverpod needs ProviderScope at the root to:
  // 1. Store all provider states
  // 2. Enable provider overriding for tests
  // 3. Handle provider lifecycle (create, dispose)
  // 
  // Without ProviderScope, ref.watch() would throw an error.
  runApp(
    const ProviderScope(
      child: RoadGuardApp(),
    ),
  );
}

/// Root application widget
/// 
/// TEACHING NOTE:
/// We use ConsumerWidget (from Riverpod) instead of StatelessWidget
/// because we might need to read providers in the future
/// (like user preferences for theme).
/// 
/// ConsumerWidget gives us access to `ref` which lets us:
/// - ref.watch() - rebuild when provider changes
/// - ref.read() - read once without rebuilding
/// - ref.listen() - perform side effects on changes
class RoadGuardApp extends ConsumerWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // ==========================================
      // APP CONFIGURATION
      // ==========================================
      
      // App title shown in task switcher
      title: 'RoadGuard',
      
      // Disable the debug banner in top-right corner
      debugShowCheckedModeBanner: false,
      
      // ==========================================
      // THEME
      // ==========================================
      // Apply our custom theme to the entire app
      // This makes all Material widgets use our colors,
      // typography, and dimensions automatically.
      theme: createAppTheme(),
      
      // ==========================================
      // HOME SCREEN
      // ==========================================
      // TODO: Replace with GoRouter navigation
      // For now, we show a simple placeholder screen
      home: const _PlaceholderHomeScreen(),
    );
  }
}

/// Temporary placeholder screen
/// 
/// This will be replaced with proper routing in the next step.
/// We create this to verify the app builds and runs correctly.
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppDimensions.spacingXl),
              
              // App title
              Text(
                'RoadGuard',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppDimensions.spacingSm),
              
              // Tagline
              Text(
                'Your Digital Copilot',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: AppDimensions.spacingXxl),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text(
                      'Project Setup Complete',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimensions.spacingXl),
              
              // Version info
              Text(
                'v0.1.0 • Week 1 Foundation',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
