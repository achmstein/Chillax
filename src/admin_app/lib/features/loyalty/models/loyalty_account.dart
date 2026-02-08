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

/// Represents a customer's loyalty account
class LoyaltyAccount {
  final int id;
  final String userId;
  final String? userName;
  final int pointsBalance;
  final int lifetimePoints;
  final LoyaltyTier currentTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoyaltyAccount({
    required this.id,
    required this.userId,
    this.userName,
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.currentTier,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name for UI (uses userName if available, otherwise userId)
  String get displayName => userName ?? userId;

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      id: json['id'] as int,
      userId: json['userId'] as String,
      userName: json['userName'] ?? json['userDisplayName'] as String?,
      pointsBalance: json['pointsBalance'] as int,
      lifetimePoints: json['lifetimePoints'] as int,
      currentTier: LoyaltyTier.fromString(json['currentTier'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        if (userName != null) 'userName': userName,
        'pointsBalance': pointsBalance,
        'lifetimePoints': lifetimePoints,
        'currentTier': currentTier.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Get tier color for UI display
  int get tierColorValue => currentTier.colorValue;

  /// Get tier gradient colors for UI display
  List<int> get tierGradientColors => currentTier.gradientColors;

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
        return 0; // Already at max tier
    }
  }

  /// Get the next tier (if any)
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
}

/// Balance summary DTO
class LoyaltyBalance {
  final int balance;
  final int lifetimePoints;
  final String tier;

  const LoyaltyBalance({
    required this.balance,
    required this.lifetimePoints,
    required this.tier,
  });

  factory LoyaltyBalance.fromJson(Map<String, dynamic> json) {
    return LoyaltyBalance(
      balance: json['balance'] as int,
      lifetimePoints: json['lifetimePoints'] as int,
      tier: json['tier'] as String,
    );
  }
}
