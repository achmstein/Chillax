import 'package:flutter/material.dart';
import '../models/rating.dart';

/// Star rating widget - can be interactive or read-only
class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32.0,
    this.activeColor = const Color(0xFFFFB800),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(starIndex) : null,
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: size,
            color: isFilled ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}

/// Display an existing rating - minimalistic inline design
class RatingDisplay extends StatelessWidget {
  final OrderRating rating;
  final Color? color;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StarRating(
      rating: rating.ratingValue,
      size: 16,
      inactiveColor: color ?? const Color(0xFFE0E0E0),
    );
  }
}
