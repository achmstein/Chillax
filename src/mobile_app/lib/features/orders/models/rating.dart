/// Order rating model for displaying existing ratings
class OrderRating {
  final int ratingValue;
  final String? comment;
  final DateTime createdAt;

  OrderRating({
    required this.ratingValue,
    this.comment,
    required this.createdAt,
  });

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    return OrderRating(
      ratingValue: json['ratingValue'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratingValue': ratingValue,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Submit rating request model for API
class SubmitRatingRequest {
  final int ratingValue;
  final String? comment;

  SubmitRatingRequest({
    required this.ratingValue,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'ratingValue': ratingValue,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
