import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import 'package:road_guard/core/router/routes.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/core/theme/app_colors.dart';
import 'package:road_guard/features/trip/application/trip_service.dart';
import 'package:road_guard/features/trip/data/repositories/rating_repository.dart';
import 'package:road_guard/features/trip/domain/constants/rating_constants.dart';
import 'package:road_guard/features/trip/domain/models/rating_model.dart';
import 'package:road_guard/features/trip/domain/models/trip_model.dart';
import 'package:road_guard/shared/services/storage_service.dart';
import 'package:road_guard/shared/utils/plate_number_formatter.dart';
import 'package:road_guard/shared/utils/plate_validator.dart';
import 'package:road_guard/features/search/presentation/plate_scanner_screen.dart';
import 'package:uuid/uuid.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const RatingScreen({super.key, required this.trip});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  bool? _isGood;
  final Set<String> _selectedTags = {};
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip.plateNumber != null &&
        widget.trip.plateNumber!.isNotEmpty) {
      _plateController.text = widget.trip.plateNumber!;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PlateScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _plateController.text = result;
      });
    }
  }

  Future<void> _saveTrip({bool skipRating = false}) async {
    setState(() => _isSaving = true);

    try {
      String? normalizedPlate;
      if (_plateController.text.trim().isNotEmpty) {
        normalizedPlate = PlateValidator.normalize(_plateController.text);
      }

      RatingModel? rating;
      if (!skipRating && _isGood != null && normalizedPlate != null) {
        rating = RatingModel(
          id: const Uuid().v4(),
          plateNumber: normalizedPlate,
          raterId: StorageService.instance.userId,
          isGood: _isGood!,
          tags: _selectedTags.toList(),
          comment: _commentController.text.isNotEmpty
              ? _commentController.text
              : null,
          tripId: widget.trip.id,
        );
      }

      // Save trip first so there's no orphan rating if trip save fails
      final updatedTrip = widget.trip.copyWith(
        ratingId: rating?.id,
        plateNumber: normalizedPlate ?? widget.trip.plateNumber,
        notes: _commentController.text.isNotEmpty
            ? _commentController.text
            : widget.trip.notes,
      );

      await ref
          .read(tripControllerProvider.notifier)
          .saveCompletedTrip(updatedTrip);

      // Save rating after trip succeeds
      if (rating != null) {
        await ref.read(ratingRepositoryProvider).saveRating(rating);
      }

      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Couldn\'t save your trip. Please try again.',
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
    final colorScheme = theme.colorScheme;
    final availableTags = _isGood == true ? goodDriverTags : badDriverTags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        automaticallyImplyLeading: false,
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
            // === Trip Stats ===
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'DISTANCE',
                    value:
                        '${widget.trip.distance.toStringAsFixed(1)} km',
                  ),
                ),
                const Gap(AppDimensions.spacingMd),
                Expanded(
                  child: _StatCard(
                    label: 'TIME',
                    value:
                        '${widget.trip.endTime!.difference(widget.trip.startTime).inMinutes}:${(widget.trip.endTime!.difference(widget.trip.startTime).inSeconds % 60).toString().padLeft(2, '0')} min',
                  ),
                ),
              ],
            ),
            const Gap(AppDimensions.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'FASTEST',
                    value:
                        '${(widget.trip.maxSpeed * 3.6).toStringAsFixed(0)} km/h',
                    isAlert: (widget.trip.maxSpeed * 3.6) > 80,
                  ),
                ),
                const Gap(AppDimensions.spacingMd),
                Expanded(
                  child: _StatCard(
                    label: 'AVERAGE',
                    value:
                        '${(widget.trip.avgSpeed * 3.6).toStringAsFixed(0)} km/h',
                  ),
                ),
              ],
            ),

            const Gap(AppDimensions.spacingXl),
            const Divider(),
            const Gap(AppDimensions.spacingMd),

            // === Plate Number Input ===
            Text(
              'Car number',
              style: theme.textTheme.titleMedium,
            ),
            const Gap(AppDimensions.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [PlateNumberFormatter()],
                    decoration: InputDecoration(
                      hintText: 'e.g. GR-1234-24',
                      prefixIcon: const Icon(LucideIcons.car),
                      suffixIcon: _plateController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x),
                              onPressed: () {
                                _plateController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),  
                  ),
                ),
                const Gap(AppDimensions.spacingSm),
                SizedBox(
                  height: AppDimensions.inputHeight,
                  child: FilledButton.tonalIcon(
                    onPressed: _openScanner,
                    icon: const Icon(LucideIcons.camera, size: 20),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),

            const Gap(AppDimensions.spacingXl),

            // === Good/Bad Selection ===
            Text(
              'How was this driver?',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(AppDimensions.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _RatingChoice(
                    icon: LucideIcons.thumbsUp,
                    label: 'Good',
                    isSelected: _isGood == true,
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _isGood = true;
                        _selectedTags.clear();
                      });
                    },
                  ),
                ),
                const Gap(AppDimensions.spacingMd),
                Expanded(
                  child: _RatingChoice(
                    icon: LucideIcons.thumbsDown,
                    label: 'Bad',
                    isSelected: _isGood == false,
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _isGood = false;
                        _selectedTags.clear();
                      });
                    },
                  ),
                ),
              ],
            ),

            // === Tag Chips ===
            if (_isGood != null) ...[
              const Gap(AppDimensions.spacingLg),
              Text(
                'Quick feedback (optional)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Gap(AppDimensions.spacingSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: (_isGood! ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.2),
                    checkmarkColor: _isGood! ? AppColors.success : AppColors.error,
                  );
                }).toList(),
              ),
            ],

            const Gap(AppDimensions.spacingLg),

            // === Comment ===
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Add a comment (optional)',
                hintText: 'Any feedback about the driver?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const Gap(AppDimensions.spacingXl),

            // === Save Button ===
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveTrip(),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(
                        _isGood != null && _plateController.text.isNotEmpty
                            ? 'Submit rating'
                            : 'Save trip',
                      ),
              ),
            ),
            const Gap(AppDimensions.spacingMd),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => _saveTrip(skipRating: true),
              child: const Text('Skip rating'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Good/Bad choice card.
class _RatingChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RatingChoice({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? color : null),
            const Gap(8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
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
        color: isAlert
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isAlert
              ? theme.colorScheme.error
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color:
                  isAlert ? theme.colorScheme.onErrorContainer : null,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isAlert
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

