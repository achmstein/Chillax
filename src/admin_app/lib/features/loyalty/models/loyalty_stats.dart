/// Loyalty program statistics
class LoyaltyStats {
  final int totalAccounts;
  final Map<String, int> accountsByTier;
  final int pointsIssuedToday;
  final int pointsIssuedThisWeek;
  final int pointsIssuedThisMonth;

  const LoyaltyStats({
    required this.totalAccounts,
    required this.accountsByTier,
    required this.pointsIssuedToday,
    required this.pointsIssuedThisWeek,
    required this.pointsIssuedThisMonth,
  });

  factory LoyaltyStats.fromJson(Map<String, dynamic> json) {
    return LoyaltyStats(
      totalAccounts: json['totalAccounts'] as int,
      accountsByTier: Map<String, int>.from(json['accountsByTier'] as Map),
      pointsIssuedToday: json['pointsIssuedToday'] as int,
      pointsIssuedThisWeek: json['pointsIssuedThisWeek'] as int,
      pointsIssuedThisMonth: json['pointsIssuedThisMonth'] as int,
    );
  }

  /// Get count for a specific tier
  int getCountForTier(String tier) {
    return accountsByTier[tier] ?? 0;
  }
}

/// Tier information
class TierInfo {
  final String name;
  final int pointsRequired;
  final String benefits;

  const TierInfo({
    required this.name,
    required this.pointsRequired,
    required this.benefits,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      name: json['name'] as String,
      pointsRequired: json['pointsRequired'] as int,
      benefits: json['benefits'] as String,
    );
  }
}
