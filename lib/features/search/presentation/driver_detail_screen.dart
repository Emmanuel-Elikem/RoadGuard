/// Driver Detail Screen — displays a driver's rating profile.
///
/// Shows plate number, rating summary (good/bad percentages),
/// common tags, recent ratings, and a "Rate this driver" action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/theme.dart';
import '../../../shared/services/storage_service.dart';
import '../../trip/data/repositories/rating_repository.dart';
import '../../trip/domain/constants/rating_constants.dart';
import '../../trip/domain/models/driver_model.dart';
import '../../trip/domain/models/rating_model.dart';

class DriverDetailScreen extends ConsumerStatefulWidget {
  final String plateNumber;

  const DriverDetailScreen({super.key, required this.plateNumber});

  @override
  ConsumerState<DriverDetailScreen> createState() =>
      _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = ref.watch(ratingRepositoryProvider);
    final driver = repo.getDriver(widget.plateNumber);
    final ratings = repo.getRatingsForPlate(widget.plateNumber);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Text('Driver Profile', style: theme.textTheme.titleLarge),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => context.pop(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLg,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.spacingSm),

                // Plate number badge
                _PlateHeader(plateNumber: widget.plateNumber, region: driver?.region),
                const SizedBox(height: AppDimensions.spacingLg),

                // Rating summary
                if (driver != null && driver.totalRatings > 0) ...[
                  _RatingSummary(driver: driver),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // Common tags
                  if (driver.commonTags.isNotEmpty) ...[
                    _CommonTags(tags: driver.commonTags),
                    const SizedBox(height: AppDimensions.spacingLg),
                  ],
                ] else ...[
                  _NoRatingsYet(),
                  const SizedBox(height: AppDimensions.spacingLg),
                ],

                // Recent ratings
                if (ratings.isNotEmpty) ...[
                  Text(
                    'Recent ratings',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  ...ratings.take(20).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingSm,
                      ),
                      child: _RatingCard(rating: r),
                    ),
                  ),
                ],

                // Bottom spacing for FAB
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

      // Rate this driver FAB — only shown if user rode with this driver
      floatingActionButton: repo.hasTripsWithPlate(widget.plateNumber)
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: FloatingActionButton.extended(
                  onPressed: () => _navigateToRate(context),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  icon: const Icon(LucideIcons.edit3),
                  label: const Text('Rate this driver'),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _navigateToRate(BuildContext context) {
    final repo = ref.read(ratingRepositoryProvider);
    if (!repo.hasTripsWithPlate(widget.plateNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You can only rate drivers you\'ve had a trip with.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickRatingSheet(plateNumber: widget.plateNumber),
    ).then((rated) {
      if (rated == true && mounted) {
        setState(() {});
      }
    });
  }
}

// ─── Plate Header ──────────────────────────────────────────

class _PlateHeader extends StatelessWidget {
  final String plateNumber;
  final String? region;

  const _PlateHeader({required this.plateNumber, this.region});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          // Plate badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              plateNumber,
              style: AppTypography.numberPlate.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          if (region != null) ...[
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              region!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Rating Summary ────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  final DriverModel driver;

  const _RatingSummary({required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goodPct = (driver.goodPercentage * 100).round();
    final badPct = 100 - goodPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total count
        Center(
          child: Text(
            'Based on ${driver.totalRatings} rating${driver.totalRatings == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),

        // Good / Bad cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: LucideIcons.thumbsUp,
                label: 'GOOD',
                percentage: goodPct,
                count: driver.goodRatings,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: _SummaryCard(
                icon: LucideIcons.thumbsDown,
                label: 'BAD',
                percentage: badPct,
                count: driver.badRatings,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int percentage;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.percentage,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            '$percentage%',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Common Tags ───────────────────────────────────────────

class _CommonTags extends StatelessWidget {
  final List<String> tags;

  const _CommonTags({required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common tags',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: tags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── No Ratings Yet ────────────────────────────────────────

class _NoRatingsYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.star,
              size: 36,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'No ratings yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Take a trip with this driver to leave a rating',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rating Card ───────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final RatingModel rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGood = rating.isGood;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + text + date
          Row(
            children: [
              Icon(
                isGood ? LucideIcons.thumbsUp : LucideIcons.thumbsDown,
                size: 18,
                color: isGood ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                isGood ? 'Good driver' : 'Bad driver',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isGood ? AppColors.success : AppColors.error,
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(rating.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          // Tags
          if (rating.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: rating.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Comment
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              '"${rating.comment}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ─── Quick Rating Sheet ────────────────────────────────────


class _QuickRatingSheet extends ConsumerStatefulWidget {
  final String plateNumber;

  const _QuickRatingSheet({required this.plateNumber});

  @override
  ConsumerState<_QuickRatingSheet> createState() => _QuickRatingSheetState();
}

class _QuickRatingSheetState extends ConsumerState<_QuickRatingSheet> {
  bool? _isGood;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<String> get _availableTags => _isGood == true ? goodDriverTags : badDriverTags;

  Future<void> _save() async {
    if (_isGood == null) return;

    setState(() => _isSaving = true);

    try {
      final rating = RatingModel(
        id: const Uuid().v4(),
        plateNumber: widget.plateNumber,
        raterId: StorageService.instance.userId,
        isGood: _isGood!,
        tags: _selectedTags.toList(),
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      final repo = ref.read(ratingRepositoryProvider);
      await repo.saveRating(rating);

      if (mounted) {
        Navigator.of(context).pop(true); // return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save rating. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
          AppDimensions.spacingLg,
          AppDimensions.spacingLg,
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
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),

            // Title
            Text(
              'Rate this driver',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.plateNumber,
              style: AppTypography.numberPlate.copyWith(
                color: colorScheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),

            // Good / Bad choice
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    icon: LucideIcons.thumbsUp,
                    label: 'Good',
                    color: AppColors.success,
                    isSelected: _isGood == true,
                    onTap: () => setState(() {
                      _isGood = true;
                      _selectedTags.clear();
                    }),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                Expanded(
                  child: _ChoiceButton(
                    icon: LucideIcons.thumbsDown,
                    label: 'Bad',
                    color: AppColors.error,
                    isSelected: _isGood == false,
                    onTap: () => setState(() {
                      _isGood = false;
                      _selectedTags.clear();
                    }),
                  ),
                ),
              ],
            ),

            // Tags
            if (_isGood != null) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Wrap(
                spacing: AppDimensions.spacingSm,
                runSpacing: AppDimensions.spacingSm,
                children: _availableTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: colorScheme.primary,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    side: BorderSide(
                      color: selected
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  );
                }).toList(),
              ),

              // Comment
              const SizedBox(height: AppDimensions.spacingMd),
              TextField(
                controller: _commentController,
                maxLines: 2,
                maxLength: 200,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMd,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),

              // Submit
              const SizedBox(height: AppDimensions.spacingMd),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit rating'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.5), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
