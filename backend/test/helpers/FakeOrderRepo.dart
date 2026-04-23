import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/model/entities/Order.dart';
import 'package:backend/model/enums/OrderStatus.dart';
import 'package:postgres/postgres.dart';

/// Fake-репозиторий заказов для юнит-тестов (без обращения к БД).
class FakeOrderRepository extends OrderRepository {
  final Map<int, Order> _orders = {};
  Order? nextCreated;
  bool throwOnCreate = false;
  String createError = 'DB error';

  FakeOrderRepository() : super(PostgreSQLConnection('test', 5432, 'test'));

  void seed(Order order) => _orders[order.id] = order;

  @override
  Future<Order?> findById(int id) async => _orders[id];

  @override
  Future<Order> createWithPayment(Map<String, dynamic> data) async {
    if (throwOnCreate) throw Exception(createError);
    return nextCreated!;
  }

  @override
  Future<Order?> updateStatus(int id, OrderStatus status) async {
    final o = _orders[id];
    if (o == null) return null;
    final updated = Order(
      id: o.id, productsId: o.productsId, userId: o.userId, pointId: o.pointId,
      date: o.date, totalPrice: o.totalPrice, createdAt: o.createdAt, status: status,
    );
    _orders[id] = updated;
    return updated;
  }

  @override
  Future<Order?> deleteOrder(int id) async => _orders.remove(id);

  @override
  Future<List<Order>> getAllOrders({
    OrderStatus? status, int limit = 20, int offset = 0,
  }) async {
    final list = _orders.values.where((o) => status == null || o.status == status).toList();
    return list.skip(offset).take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? params}) async => [];
}