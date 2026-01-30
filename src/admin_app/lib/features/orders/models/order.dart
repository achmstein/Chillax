/// Order status - values must match backend OrderStatus enum
/// Note: Backend returns status as string, not int
enum OrderStatus {
  awaitingValidation(1, 'AwaitingValidation'),
  submitted(2, 'Submitted'),
  confirmed(3, 'Confirmed'),
  cancelled(4, 'Cancelled');

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
  final String? userId;
  final String? userName;
  final DateTime date;
  final OrderStatus status;
  final String? description;
  final String? roomName;
  final String? customerNote;
  final double total;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.userId,
    this.userName,
    required this.date,
    required this.status,
    this.description,
    this.roomName,
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
      userId: json['userId'] ?? json['UserId'] as String?,
      userName: json['userName'] ?? json['UserName'] ?? json['userDisplayName'] ?? json['UserDisplayName'] as String?,
      date: DateTime.parse((json['date'] ?? json['Date']) as String),
      status: status,
      description: json['description'] ?? json['Description'] as String?,
      roomName: json['roomName'] ?? json['RoomName'] as String?,
      customerNote: json['customerNote'] ?? json['CustomerNote'] as String?,
      total: ((json['total'] ?? json['Total']) as num).toDouble(),
      items: (orderItems as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
