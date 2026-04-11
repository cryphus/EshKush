enum OrderStatus { pending, processing, completed, cancelled }

OrderStatus orderStatusFromString(String status) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == status,
    orElse: () => OrderStatus.pending,
  );
}

class Order {
  final int id;
  final List<int> productsId;
  final int userId;
  final int pointId;
  final DateTime date;
  final OrderStatus status;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.productsId,
    required this.userId,
    required this.pointId,
    required this.date,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        productsId: (json['products_id'] as List<dynamic>?)?.cast<int>() ?? [],
        userId: json['user_id'] as int,
        pointId: json['point_id'] as int,
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        status: orderStatusFromString(json['status'] as String? ?? 'pending'),
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'products_id': productsId,
        'user_id': userId,
        'point_id': pointId,
        'date': date.toIso8601String(),
        'status': status.name,
        'total_price': totalPrice,
      };

  bool get isPending => status == OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
}
