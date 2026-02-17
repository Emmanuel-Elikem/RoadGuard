/// Stats Screen - Trip history and statistics from Hive storage.
///
/// Full-scroll layout: stats cards scroll away with trip list.
/// Tappable trip cards show detail bottom sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/services/storage_service.dart';
import '../../trip/domain/models/trip_model.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trips = StorageService.instance.tripsBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: trips.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: _EmptyState(),
              )
            : _StatsContent(trips: trips),
      ),
    );
  }
}

/// Full-scroll stats content - everything scrolls together.
class _StatsContent extends StatelessWidget {
  final List<TripModel> trips;

  const _StatsContent({required this.trips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Aggregate stats
    final totalTrips = trips.length;
    final totalDistance = trips.fold<double>(0, (sum, t) => sum + t.distance);
    final totalDuration = trips.fold<Duration>(
      Duration.zero,
      (sum, t) {
        if (t.endTime != null) {
          return sum + t.endTime!.difference(t.startTime);
        }
        return sum;
      },
    );
    final avgSpeed = trips.isEmpty
        ? 0.0
        : trips.fold<double>(0, (sum, t) => sum + t.avgSpeed * 3.6) /
            totalTrips;
    final topSpeed = trips.isEmpty
        ? 0.0
        : trips.map((t) => t.maxSpeed * 3.6).reduce((a, b) => a > b ? a : b);

    final displayTrips = trips.length > 50 ? trips.sublist(0, 50) : trips;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.floatingNavBarSafeArea,
      ),
      itemCount: displayTrips.length + 4, // header + 2 stat rows + trips header + trips
      itemBuilder: (context, index) {
        // 0: Header
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Trips', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '$totalTrips trip${totalTrips == 1 ? '' : 's'} so far',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
            ],
          );
        }

        // 1: Stats row 1
        if (index == 1) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.spacingSm),
            child: Row(
              children: [
                _SummaryCard(
                  icon: LucideIcons.navigation,
                  label: 'Total Distance',
                  value: '${totalDistance.toStringAsFixed(1)} km',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                _SummaryCard(
                  icon: LucideIcons.timer,
                  label: 'Total Time',
                  value: _formatDuration(totalDuration),
                  color: colorScheme.secondary,
                ),
              ],
            ),
          );
        }

        // 2: Stats row 2
        if (index == 2) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.spacingLg),
            child: Row(
              children: [
                _SummaryCard(
                  icon: LucideIcons.gauge,
                  label: 'Avg Speed',
                  value: '${avgSpeed.toStringAsFixed(0)} km/h',
                  color: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                _SummaryCard(
                  icon: LucideIcons.zap,
                  label: 'Fastest speed',
                  value: '${topSpeed.toStringAsFixed(0)} km/h',
                  color: topSpeed >
                          StorageService.instance.speedLimitThreshold
                      ? AppColors.error
                      : colorScheme.tertiary,
                ),
              ],
            ),
          );
        }

        // 3: "Recent Trips" header
        if (index == 3) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.spacingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Trips',
                    style: theme.textTheme.titleMedium),
                if (displayTrips.length < trips.length)
                  Text(
                    'Showing ${displayTrips.length} of ${trips.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          );
        }

        // 4+: Trip cards
        final tripIndex = index - 4;
        return Padding(
          padding:
              const EdgeInsets.only(bottom: AppDimensions.spacingSm),
          child: _TripCard(
            trip: displayTrips[tripIndex],
            onTap: () =>
                _showTripDetail(context, displayTrips[tripIndex]),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m';
    }
    return '${d.inSeconds}s';
  }

  void _showTripDetail(BuildContext context, TripModel trip) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = trip.endTime != null
        ? trip.endTime!.difference(trip.startTime)
        : Duration.zero;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.spacingLg)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingXl + bottomPadding + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Title
              Text('Trip Details',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                _formatFullDate(trip.startTime),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingLg),

              // Stats grid
              Row(
                children: [
                  _DetailStat(
                    icon: LucideIcons.navigation,
                    label: 'Distance',
                    value:
                        '${trip.distance.toStringAsFixed(2)} km',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _DetailStat(
                    icon: LucideIcons.timer,
                    label: 'Duration',
                    value: _formatDetailDuration(duration),
                    color: colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Row(
                children: [
                  _DetailStat(
                    icon: LucideIcons.gauge,
                    label: 'Average speed',
                    value:
                        '${(trip.avgSpeed * 3.6).toStringAsFixed(1)} km/h',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _DetailStat(
                    icon: LucideIcons.zap,
                    label: 'Top speed',
                    value:
                        '${(trip.maxSpeed * 3.6).toStringAsFixed(1)} km/h',
                    color: (trip.maxSpeed * 3.6) >
                            StorageService
                                .instance.speedLimitThreshold
                        ? AppColors.error
                        : colorScheme.tertiary,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingSm),

              // Time info
              Row(
                children: [
                  _DetailStat(
                    icon: LucideIcons.clock,
                    label: 'Started',
                    value: _formatTime(trip.startTime),
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _DetailStat(
                    icon: LucideIcons.clock4,
                    label: 'Ended',
                    value: trip.endTime != null
                        ? _formatTime(trip.endTime!)
                        : 'In Progress',
                    color: colorScheme.outline,
                  ),
                ],
              ),

              // Plate number
              if (trip.plateNumber != null &&
                  trip.plateNumber!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingMd),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.car,
                          size: 18,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Text('Vehicle: ${trip.plateNumber}',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],

              // Rating
              if (trip.rating != null) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.star,
                              size: 18,
                              color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            '${trip.rating!.rating} out of 5',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (trip.rating!.comment != null &&
                          trip.rating!.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(trip.rating!.comment!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            )),
                      ],
                      if (trip.rating!.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: trip.rating!.tags.map((tag) {
                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        AppDimensions
                                            .radiusFull),
                              ),
                              child: Text(tag,
                                  style: theme
                                      .textTheme.labelSmall
                                      ?.copyWith(
                                    color:
                                        colorScheme.primary,
                                  )),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Notes
              if (trip.notes != null &&
                  trip.notes!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingSm),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.stickyNote,
                          size: 18,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(trip.notes!,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        );
      },
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  String _formatDetailDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m '
          '${d.inSeconds.remainder(60)}s';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}

/// Summary stat card.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual trip card - tappable.
class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = trip.endTime != null
        ? trip.endTime!.difference(trip.startTime)
        : Duration.zero;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
                color:
                    colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Date + rating row
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(trip.startTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trip.rating != null) ...[
                    Icon(LucideIcons.star,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.rating!.rating}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingSm),

              // Stats row
              Row(
                children: [
                  _TripStat(
                    icon: LucideIcons.navigation,
                    value:
                        '${trip.distance.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  _TripStat(
                    icon: LucideIcons.timer,
                    value: _formatSmallDuration(duration),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  _TripStat(
                    icon: LucideIcons.gauge,
                    value:
                        '${(trip.avgSpeed * 3.6).toStringAsFixed(0)} km/h',
                  ),
                  const Spacer(),
                  _TripStat(
                    icon: LucideIcons.zap,
                    value:
                        '${(trip.maxSpeed * 3.6).toStringAsFixed(0)} km/h',
                    color: (trip.maxSpeed * 3.6) >
                            StorageService
                                .instance.speedLimitThreshold
                        ? AppColors.error
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSmallDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m';
    }
    return '${d.inSeconds}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final days = [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ];
      return '${days[date.weekday - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Detail stat card for bottom sheet.
class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }
}

/// Small stat for trip card.
class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _TripStat({
    required this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ??
              colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Empty state when no trips recorded.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.barChart3,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text('No Trips Yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Start monitoring a trip from the home screen\nto see your trips here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
