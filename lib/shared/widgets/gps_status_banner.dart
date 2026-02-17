/// GPS Status Banner - Signal quality indicator during tracking.
///
/// A slim, animated banner that communicates GPS signal issues
/// in plain language. Hidden when signal is good.
library;

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../services/location_service.dart';

/// Animated banner showing GPS signal quality during active tracking.
///
/// Only visible when signal is not [GpsSignalQuality.good].
/// Slides in/out with animation and shows a pulsing dot for
/// acquiring/lost states.
class GpsStatusBanner extends StatefulWidget {
  final GpsSignalQuality quality;
  final bool isTracking;

  const GpsStatusBanner({
    super.key,
    required this.quality,
    required this.isTracking,
  });

  @override
  State<GpsStatusBanner> createState() => _GpsStatusBannerState();
}

class _GpsStatusBannerState extends State<GpsStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this);
    _updatePulse();
  }

  @override
  void didUpdateWidget(GpsStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quality != widget.quality) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    switch (widget.quality) {
      case GpsSignalQuality.acquiring:
        _pulseController
          ..duration = const Duration(milliseconds: 1200)
          ..repeat(reverse: true);
      case GpsSignalQuality.lost:
        _pulseController
          ..duration = const Duration(milliseconds: 800)
          ..repeat(reverse: true);
      default:
        _pulseController.stop();
        _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow =
        widget.isTracking && widget.quality.showBanner;

    return AnimatedSize(
      duration: shouldShow
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 250),
      curve: shouldShow ? Curves.easeOutCubic : Curves.easeIn,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: shouldShow
            ? const Duration(milliseconds: 300)
            : const Duration(milliseconds: 250),
        opacity: shouldShow ? 1.0 : 0.0,
        child: shouldShow
            ? _BannerContent(
                quality: widget.quality,
                pulseController: _pulseController,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final GpsSignalQuality quality;
  final AnimationController pulseController;

  const _BannerContent({
    required this.quality,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError =
        quality == GpsSignalQuality.poor || quality == GpsSignalQuality.lost;
    final bannerColor = isError ? AppColors.error : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Pulsing dot
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final minOpacity = quality == GpsSignalQuality.acquiring
                    ? 0.4
                    : quality == GpsSignalQuality.lost
                        ? 0.6
                        : 1.0;
                final opacity =
                    minOpacity + (1.0 - minOpacity) * pulseController.value;
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bannerColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Message
            Expanded(
              child: Text(
                quality.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
