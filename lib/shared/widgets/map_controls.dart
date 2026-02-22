/// Map Controls — Floating buttons for zoom and recenter.
///
/// Overlays on the map with glass-morphism styling matching
/// our "Digital Cockpit" design language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:road_guard/core/theme/app_colors.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/shared/providers/map_providers.dart';

/// Floating map control buttons (zoom in/out, recenter).
class MapControls extends ConsumerWidget {
  final MapController mapController;

  const MapControls({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(mapFollowUserProvider);

    return Positioned(
      right: AppDimensions.spacingMd,
      bottom: AppDimensions.spacingXl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recenter button
          _MapButton(
            icon: LucideIcons.locate,
            isActive: isFollowing,
            tooltip: 'Center on my location',
            onPressed: () {
              ref.read(mapFollowUserProvider.notifier).enable();
              final userPos = ref.read(currentLatLngProvider);
              if (userPos != null) {
                mapController.move(userPos, kTrackingZoom);
              }
            },
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Zoom in
          _MapButton(
            icon: LucideIcons.plus,
            tooltip: 'Zoom in',
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              if (currentZoom < kMaxZoom) {
                mapController.move(
                  mapController.camera.center,
                  (currentZoom + 1).clamp(kMinZoom, kMaxZoom),
                );
              }
            },
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Zoom out
          _MapButton(
            icon: LucideIcons.minus,
            tooltip: 'Zoom out',
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              if (currentZoom > kMinZoom) {
                mapController.move(
                  mapController.camera.center,
                  (currentZoom - 1).clamp(kMinZoom, kMaxZoom),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Individual map control button with glass-morphism effect.
class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isActive
                ? AppColorsDark.primary.withValues(alpha: 0.2)
                : AppColorsDark.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isActive
                  ? AppColorsDark.primary.withValues(alpha: 0.5)
                  : AppColorsDark.border,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: SizedBox(
              width: AppDimensions.iconContainerSm,
              height: AppDimensions.iconContainerSm,
              child: Icon(
                icon,
                size: AppDimensions.iconMd,
                color: isActive
                    ? AppColorsDark.primary
                    : AppColorsDark.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
