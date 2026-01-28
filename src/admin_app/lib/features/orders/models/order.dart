/// Order status
enum OrderStatus {
  submitted(1, 'Submitted'),
  confirmed(2, 'Confirmed'),
  cancelled(3, 'Cancelled');

  final int value;
  final String label;

  const OrderStatus(this.value, this.label);

  static OrderStatus fromValue(int value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.submitted,
    );
  }

  /// Parse from string (backend returns status as string like "Submitted")
  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == status.toLowerCase(),
      orElse: () => OrderStatus.submitted,
    );
  }
}

/// Order item
class OrderItem {
  final int? productId;
  final String productName;
  final double unitPrice;
  final int units;
  final String? pictureUrl;
  final String? customizationsDescription;
  final String? specialInstructions;

  OrderItem({
    this.productId,
    required this.productName,
    required this.unitPrice,
    required this.units,
    this.pictureUrl,
    this.customizationsDescription,
    this.specialInstructions,
  });

  double get totalPrice => unitPrice * units;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and PascalCase property names
    return OrderItem(
      productId: json['productId'] ?? json['ProductId'] as int?,
      productName: (json['productName'] ?? json['ProductName']) as String,
      unitPrice: ((json['unitPrice'] ?? json['UnitPrice']) as num).toDouble(),
      units: (json['units'] ?? json['Units']) as int,
      pictureUrl: json['pictureUrl'] ?? json['PictureUrl'] as String?,
      customizationsDescription: json['customizationsDescription'] ?? json['CustomizationsDescription'] as String?,
      specialInstructions: json['specialInstructions'] ?? json['SpecialInstructions'] as String?,
    );
  }
}

/// Order model
class Order {
  final int id;
  final DateTime date;
  final OrderStatus status;
  final String? description;
  final int? tableNumber;
  final String? customerNote;
  final double total;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    this.description,
    this.tableNumber,
    this.customerNote,
    required this.total,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle status as either int or string (backend returns string)
    final statusValue = json['status'] ?? json['Status'];
    final status = statusValue is int
        ? OrderStatus.fromValue(statusValue)
        : OrderStatus.fromString(statusValue as String);

    // Handle both camelCase and PascalCase property names
    final orderItems = json['orderItems'] ?? json['OrderItems'];

    return Order(
      id: json['orderNumber'] ?? json['OrderNumber'] ?? json['orderId'] ?? json['id'] as int,
      date: DateTime.parse((json['date'] ?? json['Date']) as String),
      status: status,
      description: json['description'] ?? json['Description'] as String?,
      tableNumber: json['tableNumber'] ?? json['TableNumber'] as int?,
      customerNote: json['customerNote'] ?? json['CustomerNote'] as String?,
      total: ((json['total'] ?? json['Total']) as num).toDouble(),
      items: (orderItems as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
