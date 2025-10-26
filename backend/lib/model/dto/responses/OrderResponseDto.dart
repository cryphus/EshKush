import '../../entities/Order.dart';

class OrderResponseDto {
  final int id;
  final List<int> productsId;
  final int userId;
  final int pointId;
  final DateTime date;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderResponseDto({
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

  factory OrderResponseDto.fromEntity(Order order) {
    return OrderResponseDto(
      id: order.id,
      productsId: order.productsId,
      userId: order.userId,
      pointId: order.pointId,
      date: order.date,
      status: order.status.name.toLowerCase(),
      totalPrice: order.totalPrice,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products_id': productsId,
      'user_id': userId,
      'point_id': pointId,
      'date': date.toIso8601String(),
      'status': status,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
