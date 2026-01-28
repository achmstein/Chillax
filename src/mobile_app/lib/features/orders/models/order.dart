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
    return OrderItem(
      productId: json['productId'] as int?,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      units: json['units'] as int,
      pictureUrl: json['pictureUrl'] as String?,
      customizationsDescription: json['customizationsDescription'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
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
    final statusValue = json['status'];
    final status = statusValue is int
        ? OrderStatus.fromValue(statusValue)
        : OrderStatus.fromString(statusValue as String);

    return Order(
      // Backend returns 'orderNumber', fallback to 'orderId' or 'id'
      id: json['orderNumber'] as int? ?? json['orderId'] as int? ?? json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      status: status,
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

/// Paginated orders response
class PaginatedOrders {
  final List<Order> items;
  final int pageIndex;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedOrders({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    return PaginatedOrders(
      items: (json['items'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageIndex: json['pageIndex'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
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
