import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:road_guard/core/theme/app_colors.dart';


class StarRatingWidget extends ConsumerStatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final bool readOnly;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  ConsumerState<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends ConsumerState<StarRatingWidget> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Choose star color based on rating for feedback
    // 1-2 stars: Red (Error)
    // 3 stars: Orange (Warning)
    // 4-5 stars: Green (GoodDriver/Primary)
    Color getStarColor(int index) {
      if (index >= _rating) return isDark ? AppColorsDark.textDisabled : AppColorsLight.textDisabled;
      
      if (_rating <= 2) return theme.colorScheme.error;
      if (_rating == 3) return AppColorsLight.warning; // Use fixed warning color for now or theme based
      return AppColorsLight.ratingExcellent; // Or theme.primary
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: widget.readOnly ? null : () {
            setState(() {
              _rating = index + 1;
            });
            widget.onRatingChanged(_rating);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 40,
              color: getStarColor(index),
            ),
          ),
        );
      }),
    );
  }
}
