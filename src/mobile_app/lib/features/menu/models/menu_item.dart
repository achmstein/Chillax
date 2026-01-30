import 'dart:ui';

/// Menu item model
class MenuItem {
  final int id;
  final String name;
  final String? nameAr;
  final String description;
  final String? descriptionAr;
  final double price;
  final String? pictureUri;
  final int catalogTypeId;
  final String catalogTypeName;
  final String? catalogTypeNameAr;
  final bool isAvailable;
  final int? preparationTimeMinutes;
  final List<ItemCustomization> customizations;

  MenuItem({
    required this.id,
    required this.name,
    this.nameAr,
    required this.description,
    this.descriptionAr,
    required this.price,
    this.pictureUri,
    required this.catalogTypeId,
    required this.catalogTypeName,
    this.catalogTypeNameAr,
    this.isAvailable = true,
    this.preparationTimeMinutes,
    this.customizations = const [],
  });

  /// Get localized name based on locale
  String localizedName(Locale locale) {
    if (locale.languageCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  /// Get localized description based on locale
  String localizedDescription(Locale locale) {
    if (locale.languageCode == 'ar' && descriptionAr != null && descriptionAr!.isNotEmpty) {
      return descriptionAr!;
    }
    return description;
  }

  /// Get localized category name based on locale
  String localizedCategoryName(Locale locale) {
    if (locale.languageCode == 'ar' && catalogTypeNameAr != null && catalogTypeNameAr!.isNotEmpty) {
      return catalogTypeNameAr!;
    }
    return catalogTypeName;
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String?,
      price: (json['price'] as num).toDouble(),
      pictureUri: json['pictureUri'] as String?,
      catalogTypeId: json['catalogTypeId'] as int,
      catalogTypeName: json['catalogTypeName'] as String? ?? '',
      catalogTypeNameAr: json['catalogTypeNameAr'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      preparationTimeMinutes: json['preparationTimeMinutes'] as int?,
      customizations: (json['customizations'] as List<dynamic>?)
              ?.map((e) => ItemCustomization.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Customization group (e.g., "Roasting", "Sugar Level")
class ItemCustomization {
  final int id;
  final String name;
  final String? nameAr;
  final bool isRequired;
  final bool allowMultiple;
  final List<CustomizationOption> options;

  ItemCustomization({
    required this.id,
    required this.name,
    this.nameAr,
    this.isRequired = false,
    this.allowMultiple = false,
    this.options = const [],
  });

  /// Get localized name based on locale
  String localizedName(Locale locale) {
    if (locale.languageCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  factory ItemCustomization.fromJson(Map<String, dynamic> json) {
    return ItemCustomization(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      isRequired: json['isRequired'] as bool? ?? false,
      allowMultiple: json['allowMultiple'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => CustomizationOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Customization option (e.g., "Light Roast", "No Sugar")
class CustomizationOption {
  final int id;
  final String name;
  final String? nameAr;
  final double priceAdjustment;
  final bool isDefault;

  CustomizationOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.priceAdjustment = 0,
    this.isDefault = false,
  });

  /// Get localized name based on locale
  String localizedName(Locale locale) {
    if (locale.languageCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    return CustomizationOption(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Category model
class MenuCategory {
  final int id;
  final String name;
  final String? nameAr;

  MenuCategory({
    required this.id,
    required this.name,
    this.nameAr,
  });

  /// Get localized name based on locale
  String localizedName(Locale locale) {
    if (locale.languageCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as int,
      name: json['type'] as String? ?? json['name'] as String? ?? '',
      nameAr: json['typeAr'] as String? ?? json['nameAr'] as String?,
    );
  }
}
