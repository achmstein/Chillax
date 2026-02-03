import '../../../core/models/localized_text.dart';

/// Menu item model
class MenuItem {
  final int id;
  final LocalizedText name;
  final LocalizedText description;
  final double price;
  final String? pictureUri;
  final int catalogTypeId;
  final LocalizedText catalogTypeName;
  final bool isAvailable;
  final int? preparationTimeMinutes;
  final List<ItemCustomization> customizations;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.pictureUri,
    required this.catalogTypeId,
    required this.catalogTypeName,
    this.isAvailable = true,
    this.preparationTimeMinutes,
    this.customizations = const [],
  });

  MenuItem copyWith({
    int? id,
    LocalizedText? name,
    LocalizedText? description,
    double? price,
    String? pictureUri,
    int? catalogTypeId,
    LocalizedText? catalogTypeName,
    bool? isAvailable,
    int? preparationTimeMinutes,
    List<ItemCustomization>? customizations,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      pictureUri: pictureUri ?? this.pictureUri,
      catalogTypeId: catalogTypeId ?? this.catalogTypeId,
      catalogTypeName: catalogTypeName ?? this.catalogTypeName,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      customizations: customizations ?? this.customizations,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      description: LocalizedText.parse(json['description'] ?? ''),
      price: (json['price'] as num).toDouble(),
      pictureUri: json['pictureUri'] as String?,
      catalogTypeId: json['catalogTypeId'] as int,
      catalogTypeName: LocalizedText.parse(json['catalogTypeName'] ?? ''),
      isAvailable: json['isAvailable'] as bool? ?? true,
      preparationTimeMinutes: json['preparationTimeMinutes'] as int?,
      customizations: (json['customizations'] as List<dynamic>?)
              ?.map((e) => ItemCustomization.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'description': description.toJson(),
      'price': price,
      'pictureUri': pictureUri,
      'catalogTypeId': catalogTypeId,
      'catalogTypeName': catalogTypeName.toJson(),
      'isAvailable': isAvailable,
      'preparationTimeMinutes': preparationTimeMinutes,
      'customizations': customizations.map((e) => e.toJson()).toList(),
    };
  }
}

/// Customization group (e.g., "Roasting", "Sugar Level")
class ItemCustomization {
  final int id;
  final LocalizedText name;
  final bool isRequired;
  final bool allowMultiple;
  final List<CustomizationOption> options;

  ItemCustomization({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.allowMultiple = false,
    this.options = const [],
  });

  factory ItemCustomization.fromJson(Map<String, dynamic> json) {
    return ItemCustomization(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      isRequired: json['isRequired'] as bool? ?? false,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => CustomizationOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'isRequired': isRequired,
      'allowMultiple': allowMultiple,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

/// Customization option (e.g., "Light Roast", "No Sugar")
class CustomizationOption {
  final int id;
  final LocalizedText name;
  final double priceAdjustment;
  final bool isDefault;

  CustomizationOption({
    required this.id,
    required this.name,
    this.priceAdjustment = 0,
    this.isDefault = false,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'priceAdjustment': priceAdjustment,
      'isDefault': isDefault,
    };
  }
}

/// Category model
class MenuCategory {
  final int id;
  final LocalizedText name;

  MenuCategory({
    required this.id,
    required this.name,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    // Handle both 'type' and 'name' field names for category name
    final nameValue = json['type'] ?? json['name'];
    return MenuCategory(
      id: json['id'] as int,
      name: LocalizedText.parse(nameValue ?? ''),
    );
  }
}
