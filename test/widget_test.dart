/// RoadGuard App Test
/// 
/// This is a basic smoke test to verify the app builds and runs.
/// More comprehensive tests will be added as features are developed.
/// 
/// TEACHING NOTE:
/// Tests are organized by what they test:
/// - widget_test.dart: Tests UI rendering
/// - unit tests go in test/unit/
/// - integration tests go in integration_test/
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:road_guard/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    // Build the app wrapped in ProviderScope (required for Riverpod)
    await tester.pumpWidget(
      const ProviderScope(
        child: RoadGuardApp(),
      ),
    );

    // Verify the app title is displayed
    expect(find.text('RoadGuard'), findsOneWidget);
    
    // Verify the tagline is displayed
    expect(find.text('Your Digital Copilot'), findsOneWidget);
    
    // Verify the status indicator shows setup complete
    expect(find.text('Project Setup Complete'), findsOneWidget);
  });
}
