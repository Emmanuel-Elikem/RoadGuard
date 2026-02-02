import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/services/storage_service.dart';

/// Onboarding slide data model.
///
/// Colors are indices that map to theme colors at runtime,
/// allowing proper light/dark mode adaptation.
class OnboardingSlide {
  final IconData icon;
  final int colorIndex; // 0 = primary, 1 = secondary, 2 = tertiary
  final String title;
  final String description;

  const OnboardingSlide({
    required this.icon,
    required this.colorIndex,
    required this.title,
    required this.description,
  });
}

const _slides = [
  OnboardingSlide(
    icon: LucideIcons.gauge,
    colorIndex: 0, // primary
    title: 'Track Your Speed',
    description:
        'Know how fast you\'re going and stay within safe limits. Real-time GPS tracking keeps you informed.',
  ),
  OnboardingSlide(
    icon: LucideIcons.star,
    colorIndex: 2, // tertiary (warning-like)
    title: 'Rate Other Drivers',
    description:
        'Scan number plates and rate drivers to help others stay safe on the road.',
  ),
  OnboardingSlide(
    icon: LucideIcons.users,
    colorIndex: 1, // secondary
    title: 'Join the Community',
    description:
        'Connect with safe drivers and help make Ghana\'s roads safer for everyone.',
  ),
];

/// Onboarding screen with swipeable slides.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await StorageService.instance.setFirstLaunchComplete();
    if (mounted) {
      context.go(Routes.auth);
    }
  }

  /// Gets the appropriate color from the theme based on index.
  Color _getSlideColor(ColorScheme colorScheme, int index) {
    return switch (index) {
      0 => colorScheme.primary,
      1 => colorScheme.secondary,
      2 => colorScheme.tertiary,
      _ => colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final color = _getSlideColor(colorScheme, slide.colorIndex);
                  return _OnboardingPage(slide: slide, iconColor: color);
                },
              ),
            ),

            // Page indicator with modern pill shape
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Action button with modern rounded style
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;
  final Color iconColor;

  const _OnboardingPage({required this.slide, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with modern rounded design
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(slide.icon, size: 64, color: iconColor),
          ),
          const SizedBox(height: AppDimensions.spacingXl),

          // Title
          Text(
            slide.title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingMd),

          // Description
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
