/// Speedometer Widget - Circular gauge displaying current speed.
///
/// A beautiful, animated speedometer inspired by modern car dashboards.
/// Features:
/// - Circular progress ring showing speed percentage
/// - Large digital speed display
/// - Speed limit indicator with warning states
/// - Smooth animations between speed changes
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../services/location_service.dart';

/// Speed state for visual styling.
enum SpeedState {
  /// Speed is safe (under limit).
  safe,

  /// Speed is approaching limit (within 10 km/h).
  warning,

  /// Speed exceeds limit.
  danger,

  /// No speed limit set.
  unknown,
}

/// A circular speedometer widget with animated speed display.
class SpeedometerWidget extends StatelessWidget {
  /// Current speed in km/h.
  final double speed;

  /// Speed limit in km/h (null = no limit shown).
  final double? speedLimit;

  /// Maximum speed for the gauge (determines scale).
  final double maxSpeed;

  /// Size of the speedometer (width and height).
  final double size;

  /// GPS signal quality for display.
  final GpsSignalQuality signalQuality;

  /// GPS accuracy in meters (for display).
  final double? accuracy;

  const SpeedometerWidget({
    super.key,
    required this.speed,
    this.speedLimit,
    this.maxSpeed = 180,
    this.size = 280,
    this.signalQuality = GpsSignalQuality.none,
    this.accuracy,
  });

  /// Whether we have usable GPS signal.
  bool get hasSignal => signalQuality.isUsable;

  /// Determine speed state based on limit.
  SpeedState get speedState {
    if (speedLimit == null) return SpeedState.unknown;
    if (speed > speedLimit!) return SpeedState.danger;
    if (speed > speedLimit! - 10) return SpeedState.warning;
    return SpeedState.safe;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Color based on speed state
    final speedColor = switch (speedState) {
      SpeedState.safe => AppColors.success,
      SpeedState.warning => AppColors.warning,
      SpeedState.danger => AppColors.error,
      SpeedState.unknown => colorScheme.primary,
    };

    // Progress percentage (0.0 to 1.0), guard against invalid maxSpeed
    final progress = maxSpeed > 0 ? (speed / maxSpeed).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          _SpeedometerRing(
            progress: 1.0,
            color: colorScheme.surfaceContainerHighest,
            strokeWidth: 12,
            size: size,
          ),

          // Progress ring
          _SpeedometerRing(
            progress: progress,
            color: speedColor,
            strokeWidth: 12,
            size: size,
          ),

          // Glow effect when moving
          if (speed > 0)
            _SpeedometerRing(
              progress: progress,
              color: speedColor.withValues(alpha: 0.3),
              strokeWidth: 24,
              size: size,
            ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed value
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  speed.toStringAsFixed(0),
                  key: ValueKey(speed.toStringAsFixed(0)),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: hasSignal
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              // Unit label
              Text(
                'km/h',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              // Speed limit indicator
              if (speedLimit != null)
                _SpeedLimitBadge(
                  limit: speedLimit!,
                  state: speedState,
                  size: size * 0.18,
                ),

              // Signal quality indicator
              if (signalQuality != GpsSignalQuality.excellent &&
                  signalQuality != GpsSignalQuality.good) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: signalQuality == GpsSignalQuality.none
                        ? colorScheme.errorContainer
                        : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    signalQuality.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: signalQuality == GpsSignalQuality.none
                          ? colorScheme.onErrorContainer
                          : colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // Accuracy indicator (debug)
              if (accuracy != null && hasSignal)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '±${accuracy!.toStringAsFixed(0)}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The circular progress ring.
class _SpeedometerRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double size;

  const _SpeedometerRing({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // Use Tween with only 'end' to animate from current value
      // Providing 'begin' would force restart from 0 on every update
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the ring.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from bottom (270°) and sweep based on progress
    // We use 270° arc (3/4 circle) for a more gauge-like appearance
    const startAngle = 135 * (math.pi / 180); // Start at bottom-left
    const sweepRange = 270 * (math.pi / 180); // 270° total range
    final sweepAngle = sweepRange * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Speed limit badge (like road signs).
class _SpeedLimitBadge extends StatelessWidget {
  final double limit;
  final SpeedState state;
  final double size;

  const _SpeedLimitBadge({
    required this.limit,
    required this.state,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Color based on state - use theme-aware colors
    final borderColor = switch (state) {
      SpeedState.danger => AppColors.error,
      SpeedState.warning => AppColors.warning,
      // Safe/unknown uses error container outline for standard speed limit sign look
      _ => colorScheme.error,
    };

    // Background: white-ish in light mode, surface in dark mode
    final backgroundColor = colorScheme.brightness == Brightness.light
        ? colorScheme.surface
        : colorScheme.surfaceContainerHighest;

    // Text: dark in light mode, light in dark mode
    final textColor = colorScheme.onSurface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: size * 0.1),
        boxShadow: state == SpeedState.danger
            ? [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          limit.toStringAsFixed(0),
          style: theme.textTheme.titleSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}
