import 'package:backend/model/enums/OrderStatus.dart';

class Order {
  final int id;
  final productsId;
  final int userId;
  final int pointId;
  DateTime date;
  OrderStatus status;
  double totalPrice;
  
  Order({
    required this.id,
    required this.productsId,
    required this.userId,
    required this.pointId,
    required this.date,
    required this.totalPrice,
    this.status = OrderStatus.pending
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      productsId: (json['productsId'] as List).map((e) => e as int).toList(),
      userId: json['userId'] as int,
      pointId: json['pointId'] as int,
      date: DateTime.parse(json['date'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productsId': productsId,
      'userId': userId,
      'pointId': pointId,
      'date': date.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
    };
  }

  bool get isCompleted => status == OrderStatus.completed;
  bool get isPending => status == OrderStatus.pending;
  bool get isCancelled => status == OrderStatus.cancelled;
}
