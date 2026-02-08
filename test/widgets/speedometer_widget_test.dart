/// Widget tests for SpeedometerWidget.
///
/// Tests edge cases:
/// - Speed states (safe, warning, danger)
/// - No GPS signal display
/// - Clamped progress for speeds > maxSpeed
/// - Speed limit badge visibility
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_guard/shared/services/location_service.dart';
import 'package:road_guard/shared/widgets/speedometer_widget.dart';
import 'package:road_guard/core/theme/theme.dart';

void main() {
  Widget buildSpeedometer({
    double speed = 0,
    double? speedLimit = 50,
    double maxSpeed = 180,
    GpsSignalQuality signalQuality = GpsSignalQuality.good,
    double? accuracy,
  }) {
    return MaterialApp(
      theme: createDarkTheme(),
      home: Scaffold(
        body: Center(
          child: SpeedometerWidget(
            speed: speed,
            speedLimit: speedLimit,
            maxSpeed: maxSpeed,
            signalQuality: signalQuality,
            accuracy: accuracy,
          ),
        ),
      ),
    );
  }

  group('SpeedometerWidget', () {
    group('speed display', () {
      testWidgets('shows speed value', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 45));
        expect(find.text('45'), findsOneWidget);
      });

      testWidgets('shows km/h unit', (tester) async {
        await tester.pumpWidget(buildSpeedometer());
        expect(find.text('km/h'), findsOneWidget);
      });

      testWidgets('shows 0 for zero speed', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 0));
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('shows rounded speed value', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 45.7));
        expect(find.text('46'), findsOneWidget);
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
      });
    });

    group('GPS signal quality', () {
      testWidgets('shows NO GPS when signalQuality is none', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.none,
        ));
        expect(find.text('NO GPS'), findsOneWidget);
      });

      testWidgets('shows POOR GPS for poor signal', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.poor,
        ));
        expect(find.text('POOR GPS'), findsOneWidget);
      });

      testWidgets('shows WEAK GPS for very poor signal', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.veryPoor,
        ));
        expect(find.text('WEAK GPS'), findsOneWidget);
      });

      testWidgets('hides signal badge for good quality', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.good,
        ));
        expect(find.text('NO GPS'), findsNothing);
        expect(find.text('POOR GPS'), findsNothing);
        expect(find.text('WEAK GPS'), findsNothing);
      });

      testWidgets('hides signal badge for excellent quality', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.excellent,
        ));
        expect(find.text('NO GPS'), findsNothing);
        expect(find.text('POOR GPS'), findsNothing);
      });
    });

    group('accuracy display', () {
      testWidgets('shows accuracy when provided', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.good,
          accuracy: 5,
        ));
        expect(find.text('±5m'), findsOneWidget);
      });

      testWidgets('hides accuracy when null', (tester) async {
        await tester.pumpWidget(buildSpeedometer(accuracy: null));
        expect(find.textContaining('±'), findsNothing);
      });

      testWidgets('hides accuracy when no signal', (tester) async {
        await tester.pumpWidget(buildSpeedometer(
          signalQuality: GpsSignalQuality.none,
          accuracy: 5,
        ));
        expect(find.textContaining('±'), findsNothing);
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
        await tester.pumpWidget(buildSpeedometer(
          speed: 200, // > 180 maxSpeed
          maxSpeed: 180,
        ));
        expect(find.text('200'), findsOneWidget);
        // Widget should render without issues
      });

      testWidgets('handles very high speed gracefully', (tester) async {
        await tester.pumpWidget(buildSpeedometer(speed: 999));
        expect(find.text('999'), findsOneWidget);
      });
    });
  });
}
