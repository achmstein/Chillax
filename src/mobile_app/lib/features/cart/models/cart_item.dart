import '../../menu/models/menu_item.dart';

/// Selected customization in cart
class SelectedCustomization {
  final int customizationId;
  final String customizationName;
  final int optionId;
  final String optionName;
  final double priceAdjustment;

  SelectedCustomization({
    required this.customizationId,
    required this.customizationName,
    required this.optionId,
    required this.optionName,
    this.priceAdjustment = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'customizationId': customizationId,
      'customizationName': customizationName,
      'optionId': optionId,
      'optionName': optionName,
      'priceAdjustment': priceAdjustment,
    };
  }
}

/// Cart item with customizations
class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final String? pictureUri;
  int quantity;
  String? specialInstructions;
  List<SelectedCustomization> selectedCustomizations;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.pictureUri,
    this.quantity = 1,
    this.specialInstructions,
    this.selectedCustomizations = const [],
  });

  /// Calculate total price including customizations
  double get totalPrice {
    final customizationsTotal =
        selectedCustomizations.fold(0.0, (sum, c) => sum + c.priceAdjustment);
    return (unitPrice + customizationsTotal) * quantity;
  }

  /// Create cart item from menu item with selected options
  factory CartItem.fromMenuItem(
    MenuItem item, {
    List<SelectedCustomization>? customizations,
    String? instructions,
  }) {
    return CartItem(
      productId: item.id,
      productName: item.name,
      unitPrice: item.price,
      pictureUri: item.pictureUri,
      selectedCustomizations: customizations ?? [],
      specialInstructions: instructions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'pictureUri': pictureUri,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'selectedCustomizations':
          selectedCustomizations.map((c) => c.toJson()).toList(),
    };
  }
}

/// Shopping cart state
class Cart {
  final List<CartItem> items;

  Cart({this.items = const []});

  /// Total number of items
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Add or update item in cart
  Cart addItem(CartItem newItem) {
    final existingIndex = items.indexWhere((i) =>
        i.productId == newItem.productId &&
        _customizationsMatch(i.selectedCustomizations, newItem.selectedCustomizations));

    if (existingIndex >= 0) {
      // Update quantity of existing item
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex].quantity += newItem.quantity;
      return Cart(items: updatedItems);
    } else {
      // Add new item
      return Cart(items: [...items, newItem]);
    }
  }

  /// Update item quantity
  Cart updateQuantity(int index, int quantity) {
    if (index < 0 || index >= items.length) return this;

    final updatedItems = List<CartItem>.from(items);
    if (quantity <= 0) {
      updatedItems.removeAt(index);
    } else {
      updatedItems[index].quantity = quantity;
    }
    return Cart(items: updatedItems);
  }

  /// Remove item from cart
  Cart removeItem(int index) {
    if (index < 0 || index >= items.length) return this;

    final updatedItems = List<CartItem>.from(items);
    updatedItems.removeAt(index);
    return Cart(items: updatedItems);
  }

  /// Clear cart
  Cart clear() => Cart(items: []);

  /// Check if two customization lists match
  bool _customizationsMatch(
      List<SelectedCustomization> a, List<SelectedCustomization> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].optionId != b[i].optionId) return false;
    }
    return true;
  }
}
