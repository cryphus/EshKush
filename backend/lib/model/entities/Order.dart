import 'package:backend/model/enums/OrderStatus.dart';

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
  
  Order({
    required this.id,
    required this.productsId,
    required this.userId,
    required this.pointId,
    required this.date,
    required this.totalPrice,
    required this.createdAt,
    this.updatedAt,
    this.status = OrderStatus.pending
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Преобразуем products_id в List<int>
      final productsId = (json['products_id'] as List?)?.map((e) {
        if (e is String) return int.parse(e);
        return e as int;
      }).toList() ?? [];

      // Преобразуем total_price в double
      final totalPrice = json['total_price'] == null ? 0.0 :
          (json['total_price'] is String 
              ? double.parse(json['total_price']) 
              : (json['total_price'] as num).toDouble());

      // Преобразуем status в OrderStatus
      final statusStr = json['status']?.toString().toLowerCase() ?? 'pending';
      final status = OrderStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => OrderStatus.pending,
      );

      // Преобразуем даты
      final date = json['date'] == null ? DateTime.now() :
          (json['date'] is DateTime 
              ? json['date'] as DateTime 
              : DateTime.parse(json['date'] as String));
          
      final createdAt = json['created_at'] == null ? DateTime.now() :
          (json['created_at'] is DateTime 
              ? json['created_at'] as DateTime 
              : DateTime.parse(json['created_at'] as String));
          
      final updatedAt = json['updated_at'] == null ? null :
          (json['updated_at'] is DateTime 
              ? json['updated_at'] as DateTime 
              : DateTime.parse(json['updated_at'] as String));

      // Преобразуем числовые поля
      final id = json['id'] == null ? 0 :
          (json['id'] is String ? int.parse(json['id']) : json['id'] as int);
      final userId = json['user_id'] == null ? 0 :
          (json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'] as int);
      final pointId = json['point_id'] == null ? 0 :
          (json['point_id'] is String ? int.parse(json['point_id']) : json['point_id'] as int);

      final order = Order(
        id: id,
        productsId: productsId,
        userId: userId,
        pointId: pointId,
        date: date,
        totalPrice: totalPrice,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      
      return order;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products_id': productsId,
      'user_id': userId,
      'point_id': pointId,
      'date': date.toIso8601String(),
      'total_price': totalPrice,
      'status': status.name.toLowerCase(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status == OrderStatus.completed;
  bool get isPending => status == OrderStatus.pending;
  bool get isCancelled => status == OrderStatus.cancelled;
}
