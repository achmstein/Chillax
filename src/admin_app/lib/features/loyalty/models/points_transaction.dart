/// Represents a points transaction
class PointsTransaction {
  final int id;
  final int points;
  final String type;
  final String? referenceId;
  final String description;
  final DateTime createdAt;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.type,
    this.referenceId,
    required this.description,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] as int,
      points: json['points'] as int,
      type: json['type'] as String,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Whether this transaction is positive (points earned)
  bool get isEarned => points > 0;

  /// Get display text for the transaction type
  String get typeDisplay {
    switch (type.toLowerCase()) {
      case 'purchase':
        return 'Purchase';
      case 'bonus':
        return 'Bonus';
      case 'referral':
        return 'Referral';
      case 'promotion':
        return 'Promotion';
      case 'redemption':
        return 'Redemption';
      case 'adjustment':
        return 'Adjustment';
      default:
        return type;
    }
  }
}
