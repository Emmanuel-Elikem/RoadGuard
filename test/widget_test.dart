/// RoadGuard App Test
///
/// Basic smoke test to verify the app builds and runs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:road_guard/main.dart';

void main() {
  testWidgets('App should render home screen with navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RoadGuardApp()));
    await tester.pumpAndSettle();

    // Verify home screen greeting is displayed
    expect(find.text('Hello, Driver'), findsOneWidget);

    // Verify floating nav bar items exist
    expect(find.text('Home'), findsOneWidget);
  });
}
