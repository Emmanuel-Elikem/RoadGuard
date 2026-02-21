import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/providers/auth_providers.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/password_reset_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/driver_detail_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../shared/services/storage_service.dart';
import '../../features/trip/domain/models/trip_model.dart';
import '../../features/trip/presentation/screens/rating_screen.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that don't require authentication
const _publicRoutes = [
  Routes.splash,
  Routes.onboarding,
  Routes.auth,
  Routes.passwordReset,
];

/// Provider for the app router with auth guards.
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to rebuild router when auth changes
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      final isPublicRoute = _publicRoutes.contains(currentPath);
      final isEmailVerificationRoute = currentPath == Routes.emailVerification;

      // Get auth status
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;

      // Sync Firebase user to Hive on every auth check
      if (isLoggedIn) {
        final storage = StorageService.instance;
        if (storage.userId != user.uid) {
          unawaited(
            storage.saveUserLogin(
              id: user.uid,
              name: user.nameOrEmail,
              isGuest: user.isAnonymous,
            ).catchError((_) {}),
          );
        }
      }

      // If user is logged in
      if (isLoggedIn) {
        // If on auth/onboarding, redirect to home
        if (currentPath == Routes.auth || currentPath == Routes.onboarding) {
          // Check if email user needs verification
          if (!user.isAnonymous && user.email != null && !user.emailVerified) {
            return Routes.emailVerification;
          }
          return Routes.home;
        }

        // Email verification redirect for unverified email users
        if (!user.isAnonymous &&
            user.email != null &&
            !user.emailVerified &&
            !isEmailVerificationRoute &&
            !isPublicRoute) {
          return Routes.emailVerification;
        }

        // If verified user on email verification screen, go home
        if (isEmailVerificationRoute && user.emailVerified) {
          return Routes.home;
        }
      }

      // If user is not logged in and trying to access protected route
      // NOTE: Also redirect from email verification screen if logged out
      if (!isLoggedIn && !isPublicRoute) {
        // Check if onboarding completed (first launch means not completed)
        final storage = StorageService.instance;
        if (storage.isFirstLaunch) {
          return Routes.onboarding;
        }
        return Routes.auth;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth flow routes
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        name: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: Routes.passwordReset,
        name: RouteNames.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: Routes.emailVerification,
        name: RouteNames.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Shell route wraps bottom navigation destinations
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            name: RouteNames.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: Routes.stats,
            name: RouteNames.stats,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: Routes.search,
            name: RouteNames.search,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: Routes.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.tripSummary,
        name: RouteNames.tripSummary,
        builder: (context, state) {
          final trip = state.extra as TripModel;
          return RatingScreen(trip: trip);
        },
      ),
      GoRoute(
        path: Routes.vehicleDetails,
        name: RouteNames.vehicleDetails,
        builder: (context, state) {
          final plateNumber = Uri.decodeComponent(
            state.pathParameters['plateNumber']!,
          );
          return DriverDetailScreen(plateNumber: plateNumber);
        },
      ),
    ],
  );
});
