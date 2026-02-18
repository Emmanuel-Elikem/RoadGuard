/// Widget tests for SpeedometerWidget.
///
/// Tests edge cases:
/// - Speed states (safe, warning, danger)
/// - Clamped progress for speeds > maxSpeed
/// - Speed limit badge visibility
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/widgets/speedometer_widget.dart';
import 'package:road_guard/shared/widgets/animated_speed_display.dart';
import 'package:road_guard/core/theme/theme.dart';

void main() {
  Widget buildSpeedometer({
    double speed = 0,
    double? speedLimit = 50,
    double maxSpeed = 180,
    bool hasSignal = true,
  }) {
    return MaterialApp(
      theme: createDarkTheme(),
      home: Scaffold(
        body: Center(
          child: SpeedometerWidget(
            speed: speed,
            speedLimit: speedLimit,
            maxSpeed: maxSpeed,
            hasSignal: hasSignal,
          ),
        ),
      ),
    );
  }

  group('SpeedometerWidget', () {
    group('speed display', () {
      testWidgets('shows speed via AnimatedSpeedDisplay', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 45));
        // AnimatedSpeedDisplay renders per-digit Text widgets
        expect(find.byType(AnimatedSpeedDisplay), findsOneWidget);
        // Individual digits: '4' and '5'
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('shows km/h unit', (tester) async {
        await tester.pumpWidget(buildSpeedometer());
        expect(find.text('km/h'), findsOneWidget);
      });

      testWidgets('shows 0 for zero speed', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 0));
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('shows rounded speed digits', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 45.7));
        // 45.7 rounds to 46 → digits '4' and '6'
        expect(find.text('4'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
      });
    });

    group('speed limit badge', () {
      testWidgets('shows speed limit when provided', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speedLimit: 50));
        expect(find.text('50'), findsOneWidget);
      });

      testWidgets('hides speed limit when null', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speedLimit: null));
        // Only speed value should show, no limit
        expect(find.text('0'), findsOneWidget);
        expect(find.text('50'), findsNothing);
      });
    });

    group('speed state', () {
      test('returns safe for speed under limit - 10', () {
        const widget = SpeedometerWidget(speed: 30, speedLimit: 50);
        expect(widget.speedState, SpeedState.safe);
      });

      test('returns warning for speed within 10 of limit', () {
        const widget = SpeedometerWidget(speed: 45, speedLimit: 50);
        expect(widget.speedState, SpeedState.warning);
      });

      test('returns danger for speed over limit', () {
        const widget = SpeedometerWidget(speed: 55, speedLimit: 50);
        expect(widget.speedState, SpeedState.danger);
      });

      test('returns unknown when no speed limit', () {
        const widget = SpeedometerWidget(speed: 45, speedLimit: null);
        expect(widget.speedState, SpeedState.unknown);
      });

      test('returns safe at exactly limit - 10', () {
        const widget = SpeedometerWidget(speed: 40, speedLimit: 50);
        expect(widget.speedState, SpeedState.safe);
      });

      test('returns warning at limit - 9', () {
        const widget = SpeedometerWidget(speed: 41, speedLimit: 50);
        expect(widget.speedState, SpeedState.warning);
      });

      test('returns danger at exactly limit + 1', () {
        const widget = SpeedometerWidget(speed: 51, speedLimit: 50);
        expect(widget.speedState, SpeedState.danger);
      });
    });

    group('progress clamping', () {
      testWidgets('handles speed > maxSpeed without overflow', (tester) async {
        // Should not throw any errors
        await tester.pumpWidget(
          buildSpeedometer(
            speed: 200, // > 180 maxSpeed
            maxSpeed: 180,
          ),
        );
        // Digits: '2', '0', '0'
        expect(find.text('2'), findsOneWidget);
        expect(find.text('0'), findsWidgets);
      });

      testWidgets('handles very high speed gracefully', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 999));
        // Digits: '9', '9', '9'
        expect(find.text('9'), findsWidgets);
      });
    });
  });
}
