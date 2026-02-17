/// Fallback error screen shown when app initialization fails.
library;

import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';

/// Widget shown when the app fails to initialize (Firebase, Hive, etc).
/// This prevents the app from crashing completely.
class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    // Use a simple theme since the app theme might not be initialized
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          error: AppColors.error,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          error: AppColors.error,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Something went wrong',
                      style: AppTypography.headlineMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'RoadGuard couldn\'t start. Please try again or reinstall the app.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Technical details have been logged.',
                        style: AppTypography.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Restart the app (requires app restart)
                        // In production, you'd restart the app here
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
