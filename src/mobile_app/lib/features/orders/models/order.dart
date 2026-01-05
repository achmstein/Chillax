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
}

/// Order item
class OrderItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final int units;
  final String? pictureUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.units,
    this.pictureUrl,
  });

  double get totalPrice => unitPrice * units;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      units: json['units'] as int,
      pictureUrl: json['pictureUrl'] as String?,
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
    return Order(
      id: json['orderId'] as int? ?? json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      status: OrderStatus.fromValue(json['status'] as int),
      description: json['description'] as String?,
      tableNumber: json['tableNumber'] as int?,
      customerNote: json['customerNote'] as String?,
      total: (json['total'] as num).toDouble(),
      items: (json['orderItems'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Create order request
class CreateOrderRequest {
  final int? tableNumber;
  final String? customerNote;

  CreateOrderRequest({
    this.tableNumber,
    this.customerNote,
  });

  Map<String, dynamic> toJson() {
    return {
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (customerNote != null) 'customerNote': customerNote,
    };
  }
}
