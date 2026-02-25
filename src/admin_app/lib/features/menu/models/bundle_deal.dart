import '../../../core/models/localized_text.dart';

/// Bundle deal model for admin
class BundleDeal {
  final int id;
  final LocalizedText name;
  final LocalizedText description;
  final double bundlePrice;
  final double originalPrice;
  final String? pictureUri;
  final bool isActive;
  final int displayOrder;
  final List<BundleDealItem> items;

  BundleDeal({
    required this.id,
    required this.name,
    required this.description,
    required this.bundlePrice,
    required this.originalPrice,
    this.pictureUri,
    this.isActive = true,
    this.displayOrder = 0,
    this.items = const [],
  });

  double get savings => originalPrice - bundlePrice;

  factory BundleDeal.fromJson(Map<String, dynamic> json) {
    return BundleDeal(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      description: LocalizedText.parse(json['description'] ?? ''),
      bundlePrice: (json['bundlePrice'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      pictureUri: json['pictureUri'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BundleDealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name.toJson(),
      'description': description.toJson(),
      'bundlePrice': bundlePrice,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'items': items.map((e) => {
        'catalogItemId': e.catalogItemId,
        'quantity': e.quantity,
      }).toList(),
    };
  }
}

/// Item within a bundle deal
class BundleDealItem {
  final int id;
  final int catalogItemId;
  final LocalizedText itemName;
  final double itemPrice;
  final int quantity;

  BundleDealItem({
    required this.id,
    required this.catalogItemId,
    required this.itemName,
    required this.itemPrice,
    this.quantity = 1,
  });

  factory BundleDealItem.fromJson(Map<String, dynamic> json) {
    return BundleDealItem(
      id: json['id'] as int,
      catalogItemId: json['catalogItemId'] as int,
      itemName: LocalizedText.parse(json['itemName'] ?? ''),
      itemPrice: (json['itemPrice'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
