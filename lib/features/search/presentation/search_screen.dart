/// Search Screen - Search trips and vehicles by plate number.
///
/// Provides a functional search bar with real-time filtering
/// against saved trips and ratings in Hive storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/utils/fuzzy_search.dart';
import '../../../shared/utils/humanize_count.dart';
import '../../trip/data/repositories/rating_repository.dart';
import '../../trip/domain/models/driver_model.dart';
import '../../trip/domain/models/rating_model.dart';
import '../../trip/domain/models/trip_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<TripModel> _tripResults = [];
  List<DriverModel> _driverResults = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _tripResults = [];
        _driverResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Fuzzy search trips (user's own only)
    final allTrips = StorageService.instance.currentUserTrips;
    final tripMatches = PlateSearchEngine.search<TripModel>(
      query: trimmed,
      items: allTrips.where((t) => t.plateNumber != null),
      getText: (t) => t.plateNumber!,
      threshold: 0.25,
    );
    // Also include exact note/id matches
    final upper = trimmed.toUpperCase();
    final noteMatches = allTrips.where((trip) {
      if (trip.notes != null && trip.notes!.toUpperCase().contains(upper)) {
        return !tripMatches.any((m) => m.item.id == trip.id);
      }
      return false;
    }).toList();

    final combinedTrips = [
      ...tripMatches.map((m) => m.item),
      ...noteMatches,
    ];

    // Fuzzy search drivers (community data)
    final repo = ref.read(ratingRepositoryProvider);
    final filteredDrivers = repo.searchDrivers(trimmed);

    setState(() {
      _tripResults = combinedTrips;
      _driverResults = filteredDrivers;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.spacingLg,
            AppDimensions.floatingNavBarSafeArea,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Search', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Find trips by plate number or notes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _search,
                  textCapitalization: TextCapitalization.characters,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter plate number (e.g. GR-1234-24)',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                              _focusNode.unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Results
              Expanded(
                child: _hasSearched
                    ? (_tripResults.isEmpty && _driverResults.isEmpty)
                        ? _NoResults(query: _searchController.text)
                        : _SearchResults(
                            trips: _tripResults,
                            drivers: _driverResults,
                          )
                    : _RecentSearchHint(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search results list with driver and trip sections.
class _SearchResults extends StatelessWidget {
  final List<TripModel> trips;
  final List<DriverModel> drivers;

  const _SearchResults({required this.trips, required this.drivers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalCount = drivers.length + trips.length;

    return ListView(
      children: [
        Text(
          '$totalCount result${totalCount == 1 ? '' : 's'} found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),

        // Driver results
        if (drivers.isNotEmpty) ...[
          Text(
            'Drivers',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...drivers.map(
            (driver) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: _DriverResultCard(driver: driver),
            ),
          ),
          if (trips.isNotEmpty)
            const SizedBox(height: AppDimensions.spacingSm),
        ],

        // Trip results
        if (trips.isNotEmpty) ...[
          Text(
            'Trips',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: _SearchResultCard(trip: trip),
            ),
          ),
        ],
      ],
    );
  }
}

/// Driver search result card — taps navigate to driver detail.
class _DriverResultCard extends StatelessWidget {
  final DriverModel driver;

  const _DriverResultCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goodPct = (driver.goodPercentage * 100).round();
    final isGood = goodPct >= 50;
    final displayPct = isGood ? goodPct : (100 - goodPct);
    final displayLabel = isGood ? 'good' : 'bad';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          Routes.vehicleDetailsPath(
            Uri.encodeComponent(driver.plateNumber),
          ),
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Plate badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSm,
                  ),
                ),
                child: Text(
                  driver.plateNumber,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),

              // Rating summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayPct% $displayLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isGood
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      '${driver.totalRatings} rating${driver.totalRatings == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual search result card.
class _SearchResultCard extends StatelessWidget {
  final TripModel trip;

  const _SearchResultCard({required this.trip});

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
        onTap: trip.plateNumber != null
            ? () => context.push(
                  Routes.vehicleDetailsPath(
                    Uri.encodeComponent(trip.plateNumber!),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plate number + date
          Row(
            children: [
              if (trip.plateNumber != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    trip.plateNumber!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
              ],
              Text(
                _formatDate(trip.startTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (trip.ratingId != null) ...[
                Builder(builder: (context) {
                  final RatingModel? rating = StorageService.instance.ratingsBox.get(trip.ratingId);
                  if (rating == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rating.isGood ? LucideIcons.thumbsUp : LucideIcons.thumbsDown,
                        size: 14,
                        color: rating.isGood ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.isGood ? 'Good' : 'Bad',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Trip stats
          Row(
            children: [
              _SmallStat(LucideIcons.navigation, '${trip.distance.toStringAsFixed(1)} km'),
              const SizedBox(width: AppDimensions.spacingMd),
              _SmallStat(LucideIcons.timer, '${duration.inMinutes}m'),
              const SizedBox(width: AppDimensions.spacingMd),
              _SmallStat(LucideIcons.zap, '${(trip.maxSpeed * 3.6).toStringAsFixed(0)} km/h'),
            ],
          ),

          // Notes
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              trip.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallStat(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// No results state.
class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No Results',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'No trips found matching "$query"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Hint shown before any search.
class _RecentSearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalTrips = StorageService.instance.currentUserTrips.length;
    final tripLabel = humanizeCount(
      totalTrips,
      suffix: totalTrips == 1 ? 'trip' : 'trips',
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.search,
            size: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Search Your Trips',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            totalTrips == 0
                ? 'Record trips to search them here'
                : 'Search through $tripLabel by plate number',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
