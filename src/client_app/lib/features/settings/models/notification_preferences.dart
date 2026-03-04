class NotificationPreferences {
  final bool orderStatusUpdates;
  final bool promotionsAndOffers;

  const NotificationPreferences({
    this.orderStatusUpdates = true,
    this.promotionsAndOffers = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      orderStatusUpdates: json['orderStatusUpdates'] as bool? ?? true,
      promotionsAndOffers: json['promotionsAndOffers'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderStatusUpdates': orderStatusUpdates,
      'promotionsAndOffers': promotionsAndOffers,
    };
  }

  NotificationPreferences copyWith({
    bool? orderStatusUpdates,
    bool? promotionsAndOffers,
  }) {
    return NotificationPreferences(
      orderStatusUpdates: orderStatusUpdates ?? this.orderStatusUpdates,
      promotionsAndOffers: promotionsAndOffers ?? this.promotionsAndOffers,
    );
  }
}
