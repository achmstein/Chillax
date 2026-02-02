/// Represents a points transaction
class PointsTransaction {
  final int id;
  final int points;
  final String type;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.type,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] as int,
      points: json['points'] as int,
      type: json['type'] as String,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Whether this transaction is positive (points earned)
  bool get isEarned => points > 0;

  /// Get the type name for display
  String get typeName {
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

  /// Get description for display (custom description or constructed from type + referenceId)
  String? get descriptionDisplay {
    // If description is provided, show it
    if (description != null && description!.isNotEmpty) {
      return description;
    }

    // Otherwise, construct from type + referenceId
    switch (type.toLowerCase()) {
      case 'purchase':
        return referenceId != null ? 'Order #$referenceId' : null;
      case 'redemption':
        return referenceId != null ? 'Order #$referenceId' : null;
      default:
        return null;
    }
  }
}
