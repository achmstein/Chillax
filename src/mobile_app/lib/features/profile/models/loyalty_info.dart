/// Loyalty tier enumeration
enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum;

  static LoyaltyTier fromString(String value) {
    return LoyaltyTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LoyaltyTier.bronze,
    );
  }

  /// Get tier primary color
  int get colorValue {
    switch (this) {
      case LoyaltyTier.bronze:
        return 0xFFCD7F32;
      case LoyaltyTier.silver:
        return 0xFFC0C0C0;
      case LoyaltyTier.gold:
        return 0xFFFFD700;
      case LoyaltyTier.platinum:
        return 0xFF7B8B9A;
    }
  }

  /// Get metallic gradient colors for tier badge
  List<int> get gradientColors {
    switch (this) {
      case LoyaltyTier.bronze:
        return [0xFFE6A855, 0xFFCD7F32, 0xFF8B5A2B]; // Light bronze -> bronze -> dark bronze
      case LoyaltyTier.silver:
        return [0xFFE8E8E8, 0xFFC0C0C0, 0xFF909090]; // Light silver -> silver -> dark silver
      case LoyaltyTier.gold:
        return [0xFFFFE55C, 0xFFFFD700, 0xFFDAA520]; // Light gold -> gold -> dark gold
      case LoyaltyTier.platinum:
        return [0xFFB8C5D0, 0xFF8B9DAE, 0xFF5C6F7E]; // Light platinum -> platinum -> dark platinum
    }
  }
}

/// Loyalty account info for mobile app
class LoyaltyInfo {
  final int pointsBalance;
  final int lifetimePoints;
  final LoyaltyTier currentTier;

  const LoyaltyInfo({
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.currentTier,
  });

  factory LoyaltyInfo.fromJson(Map<String, dynamic> json) {
    return LoyaltyInfo(
      pointsBalance: json['pointsBalance'] as int,
      lifetimePoints: json['lifetimePoints'] as int,
      currentTier: LoyaltyTier.fromString(json['currentTier'] as String),
    );
  }

  /// Get points needed for next tier
  int get pointsToNextTier {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return 1000 - lifetimePoints;
      case LoyaltyTier.silver:
        return 5000 - lifetimePoints;
      case LoyaltyTier.gold:
        return 10000 - lifetimePoints;
      case LoyaltyTier.platinum:
        return 0;
    }
  }

  /// Get next tier (if any)
  LoyaltyTier? get nextTier {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return null;
    }
  }

  /// Progress percentage to next tier (0.0 - 1.0)
  double get progressToNextTier {
    int currentThreshold;
    int nextThreshold;

    switch (currentTier) {
      case LoyaltyTier.bronze:
        currentThreshold = 0;
        nextThreshold = 1000;
        break;
      case LoyaltyTier.silver:
        currentThreshold = 1000;
        nextThreshold = 5000;
        break;
      case LoyaltyTier.gold:
        currentThreshold = 5000;
        nextThreshold = 10000;
        break;
      case LoyaltyTier.platinum:
        return 1.0;
    }

    final progress = (lifetimePoints - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }
}

/// Points transaction for history
class PointsTransaction {
  final int id;
  final int points;
  final String type;
  final String description;
  final DateTime createdAt;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] as int,
      points: json['points'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isEarned => points > 0;

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
