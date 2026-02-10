class NotificationPreferences {
  final bool orderStatusUpdates;
  final bool promotionsAndOffers;
  final bool sessionReminders;

  const NotificationPreferences({
    this.orderStatusUpdates = true,
    this.promotionsAndOffers = true,
    this.sessionReminders = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      orderStatusUpdates: json['orderStatusUpdates'] as bool? ?? true,
      promotionsAndOffers: json['promotionsAndOffers'] as bool? ?? true,
      sessionReminders: json['sessionReminders'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderStatusUpdates': orderStatusUpdates,
      'promotionsAndOffers': promotionsAndOffers,
      'sessionReminders': sessionReminders,
    };
  }

  NotificationPreferences copyWith({
    bool? orderStatusUpdates,
    bool? promotionsAndOffers,
    bool? sessionReminders,
  }) {
    return NotificationPreferences(
      orderStatusUpdates: orderStatusUpdates ?? this.orderStatusUpdates,
      promotionsAndOffers: promotionsAndOffers ?? this.promotionsAndOffers,
      sessionReminders: sessionReminders ?? this.sessionReminders,
    );
  }
}
