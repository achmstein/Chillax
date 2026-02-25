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
  final bool isOnOffer;
  final double? offerPrice;
  final bool isPopular;
  final int? preparationTimeMinutes;
  final int displayOrder;
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
    this.isOnOffer = false,
    this.offerPrice,
    this.isPopular = false,
    this.preparationTimeMinutes,
    this.displayOrder = 0,
    this.customizations = const [],
  });

  double get effectivePrice => isOnOffer && offerPrice != null ? offerPrice! : price;

  MenuItem copyWith({
    int? id,
    LocalizedText? name,
    LocalizedText? description,
    double? price,
    String? pictureUri,
    int? catalogTypeId,
    LocalizedText? catalogTypeName,
    bool? isAvailable,
    bool? isOnOffer,
    double? offerPrice,
    bool? isPopular,
    int? preparationTimeMinutes,
    int? displayOrder,
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
      isOnOffer: isOnOffer ?? this.isOnOffer,
      offerPrice: offerPrice ?? this.offerPrice,
      isPopular: isPopular ?? this.isPopular,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      displayOrder: displayOrder ?? this.displayOrder,
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
      isOnOffer: json['isOnOffer'] as bool? ?? false,
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
      preparationTimeMinutes: json['preparationTimeMinutes'] as int?,
      displayOrder: json['displayOrder'] as int? ?? 0,
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
      'isOnOffer': isOnOffer,
      'offerPrice': offerPrice,
      'isPopular': isPopular,
      'preparationTimeMinutes': preparationTimeMinutes,
      'displayOrder': displayOrder,
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
  final int displayOrder;
  final List<CustomizationOption> options;

  ItemCustomization({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.allowMultiple = false,
    this.displayOrder = 0,
    this.options = const [],
  });

  ItemCustomization copyWith({
    int? id,
    LocalizedText? name,
    bool? isRequired,
    bool? allowMultiple,
    int? displayOrder,
    List<CustomizationOption>? options,
  }) {
    return ItemCustomization(
      id: id ?? this.id,
      name: name ?? this.name,
      isRequired: isRequired ?? this.isRequired,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      displayOrder: displayOrder ?? this.displayOrder,
      options: options ?? this.options,
    );
  }

  factory ItemCustomization.fromJson(Map<String, dynamic> json) {
    return ItemCustomization(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      isRequired: json['isRequired'] as bool? ?? false,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
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
      'displayOrder': displayOrder,
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
  final int displayOrder;

  CustomizationOption({
    required this.id,
    required this.name,
    this.priceAdjustment = 0,
    this.isDefault = false,
    this.displayOrder = 0,
  });

  CustomizationOption copyWith({
    int? id,
    LocalizedText? name,
    double? priceAdjustment,
    bool? isDefault,
    int? displayOrder,
  }) {
    return CustomizationOption(
      id: id ?? this.id,
      name: name ?? this.name,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      isDefault: isDefault ?? this.isDefault,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'priceAdjustment': priceAdjustment,
      'isDefault': isDefault,
      'displayOrder': displayOrder,
    };
  }
}

/// Category model
class MenuCategory {
  final int id;
  final LocalizedText name;
  final int displayOrder;

  MenuCategory({
    required this.id,
    required this.name,
    this.displayOrder = 0,
  });

  MenuCategory copyWith({
    int? id,
    LocalizedText? name,
    int? displayOrder,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    // Handle both 'type' and 'name' field names for category name
    final nameValue = json['type'] ?? json['name'];
    return MenuCategory(
      id: json['id'] as int,
      name: LocalizedText.parse(nameValue ?? ''),
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
