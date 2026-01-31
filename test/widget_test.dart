/// RoadGuard App Test
///
/// Basic smoke test to verify the app builds and runs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_guard/features/auth/presentation/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen renders correctly', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/auth', builder: (_, __) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.pumpAndSettle();

    // Verify onboarding elements are displayed
    expect(find.text('Track Your Speed'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
