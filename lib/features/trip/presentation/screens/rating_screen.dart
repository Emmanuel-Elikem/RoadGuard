import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:road_guard/core/router/routes.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/features/trip/application/trip_service.dart';
import 'package:road_guard/features/trip/domain/models/rating_model.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/widgets/star_rating_widget.dart';


class RatingScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const RatingScreen({super.key, required this.trip});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTrip() async {
    setState(() => _isSaving = true);
    
    try {
      final updatedTrip = widget.trip.copyWith(
        rating: _rating > 0 
          ? RatingModel(
              rating: _rating, 
              timestamp: DateTime.now(),
              comment: _notesController.text.isNotEmpty ? _notesController.text : null,
            ) 
          : null,
        notes: _notesController.text,
      );

      // Verify validation? 
      // MVP: If rating > 0, we save it. If rating == 0, maybe prompt? 
      // Plan says "Prompt to rate driver".

      await ref.read(tripControllerProvider.notifier).saveCompletedTrip(updatedTrip);
      
      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
        // Show error
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to save trip: $e',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
            );
        }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        automaticallyImplyLeading: false, // Don't allow back without saving/discarding logic?
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingMd,
          AppDimensions.spacingMd,
          AppDimensions.spacingMd,
          AppDimensions.spacingXl * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.map, size: 48),
                    Gap(8),
                    Text('Map View Coming Soon (Week 8)'),
                  ],
                ),
              ),
            ),
            const Gap(AppDimensions.spacingLg),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'DISTANCE',
                    value: '${widget.trip.distance.toStringAsFixed(1)} km',
                  ),
                ),
                const Gap(AppDimensions.spacingMd),
                Expanded(
                  child: _StatCard(
                    label: 'DURATION',
                    value: '${widget.trip.endTime!.difference(widget.trip.startTime).inMinutes}:${(widget.trip.endTime!.difference(widget.trip.startTime).inSeconds % 60).toString().padLeft(2, '0')} min',
                  ),
                ),
              ],
            ),
            const Gap(AppDimensions.spacingMd),
            Row(
              children: [
                 Expanded(
                  child: _StatCard(
                    label: 'TOP SPEED',
                    value: '${(widget.trip.maxSpeed * 3.6).toStringAsFixed(0)} km/h',
                    isAlert: (widget.trip.maxSpeed * 3.6) > 80,
                  ),
                ),
                const Gap(AppDimensions.spacingMd),
                Expanded(
                  child: _StatCard(
                    label: 'AVG SPEED',
                    value: '${(widget.trip.avgSpeed * 3.6).toStringAsFixed(0)} km/h',
                  ),
                ),
              ],
            ),
            
            const Gap(AppDimensions.spacingXl),
            const Divider(),
            const Gap(AppDimensions.spacingMd),

            // Rating Section
            Text(
              'Rate this Trip',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(AppDimensions.spacingMd),
            Center(
              child: StarRatingWidget(
                onRatingChanged: (rating) {
                  setState(() => _rating = rating);
                },
              ),
            ),
             const Gap(AppDimensions.spacingLg),

            // Notes
            TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Any feedback about the driver?',
                    border: OutlineInputBorder(),
                ),
                maxLines: 3,
            ),

            const Gap(AppDimensions.spacingXl),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTrip,
                child: _isSaving 
                    ? const CircularProgressIndicator()
                    : const Text('SAVE TRIP'),
              ),
            ),
             const Gap(AppDimensions.spacingMd),
             TextButton(
                 onPressed: () {
                     // Discard? Or save without rating?
                     // Let's assume skip = save without rating
                     _saveTrip();
                 },
                 child: const Text('Skip Rating'),
             ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _StatCard({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isAlert ? theme.colorScheme.errorContainer : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
             color: isAlert ? theme.colorScheme.error : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
                color: isAlert ? theme.colorScheme.onErrorContainer : null,
                fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
                 color: isAlert ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
