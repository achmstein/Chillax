/// User's saved preference for a menu item
class UserItemPreference {
  final int catalogItemId;
  final DateTime lastUpdated;
  final List<UserPreferenceOption> selectedOptions;

  UserItemPreference({
    required this.catalogItemId,
    required this.lastUpdated,
    required this.selectedOptions,
  });

  factory UserItemPreference.fromJson(Map<String, dynamic> json) {
    return UserItemPreference(
      catalogItemId: json['catalogItemId'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
              ?.map((e) => UserPreferenceOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalogItemId': catalogItemId,
      'selectedOptions': selectedOptions.map((o) => o.toJson()).toList(),
    };
  }
}

/// A selected customization option in user preference
class UserPreferenceOption {
  final int customizationId;
  final int optionId;

  UserPreferenceOption({
    required this.customizationId,
    required this.optionId,
  });

  factory UserPreferenceOption.fromJson(Map<String, dynamic> json) {
    return UserPreferenceOption(
      customizationId: json['customizationId'] as int,
      optionId: json['optionId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customizationId': customizationId,
      'optionId': optionId,
    };
  }
}

/// Request to save preferences for multiple items
class SaveUserPreferencesRequest {
  final List<SaveItemPreference> items;

  SaveUserPreferencesRequest({required this.items});

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

/// Preference data for a single item to save
class SaveItemPreference {
  final int catalogItemId;
  final List<UserPreferenceOption> selectedOptions;

  SaveItemPreference({
    required this.catalogItemId,
    required this.selectedOptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'catalogItemId': catalogItemId,
      'selectedOptions': selectedOptions.map((o) => o.toJson()).toList(),
    };
  }
}
