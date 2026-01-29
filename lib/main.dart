/// RoadGuard - Your Digital Copilot for Road Safety
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: RoadGuardApp()));
}

/// Root application widget.
class RoadGuardApp extends ConsumerWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'RoadGuard',
      debugShowCheckedModeBanner: false,
      theme: createAppTheme(),
      home: const _PlaceholderHomeScreen(),
    );
  }
}

/// Temporary placeholder screen - will be replaced with proper routing.
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
              // App icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.shield, size: 64, color: AppColors.primary),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              Text(
                'RoadGuard',
                style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              Text(
                'Your Digital Copilot',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
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
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
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
                      style: AppTypography.labelMedium.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),

              Text('v0.1.0 • Week 1 Foundation', style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
