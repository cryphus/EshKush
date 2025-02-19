
class Order {
  final int id;
  List<String> products;
  final int userId;
  final int pointId;
  DateTime date;
  
  Order({
    required this.id,
    required this.products,
    required this.userId,
    required this.pointId,
    required this.date,
  });

}
