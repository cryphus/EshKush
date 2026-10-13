import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/model/enums/OrderStatus.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late OrderRepository repo;
  late int userId;
  late int pointId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = OrderRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  setUp(() async => TestDb.truncate(conn, [
        'order_history',
        'payment_transactions',
        'order_actions',
        'orders',
      ]));

  tearDownAll(() async => TestDb.close());

  Future<void> markPaid(int id) async {
    await conn.execute(
      "UPDATE payment_transactions SET status='completed' WHERE order_id=@id",
      substitutionValues: {'id': id},
    );
  }

  Map<String, dynamic> _orderData({double totalPrice = 250.0}) => {
        'user_id': userId,
        'point_id': pointId,
        'products_id': <int>[],
        'date': DateTime.now().toIso8601String(),
        'total_price': totalPrice,
      };

  // ── createWithPayment ─────────────────────────────────────────────────────
  group('createWithPayment', () {
    test('создаёт заказ с id > 0 атомарно', () async {
      final result = await repo.createWithPayment(_orderData());
      expect(result.id, greaterThan(0));
      expect(result.userId, userId);
      expect(result.pointId, pointId);
    });

    test('статус заказа — pending', () async {
      final result = await repo.createWithPayment(_orderData());
      expect(result.status, OrderStatus.pending);
    });

    test('создаёт payment_transaction вместе с заказом', () async {
      final result = await repo.createWithPayment(_orderData(totalPrice: 500.0));
      final ptRows = await conn.query(
        'SELECT id FROM payment_transactions WHERE order_id = @id',
        substitutionValues: {'id': result.id},
      );
      expect(ptRows.length, 1);
    });

    test('сохраняет totalPrice', () async {
      final result = await repo.createWithPayment(_orderData(totalPrice: 750.0));
      expect(result.totalPrice, 750.0);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает заказ по id', () async {
      final created = await repo.createWithPayment(_orderData());
      final found = await repo.findById(created.id);
      expect(found?.userId, userId);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── updateStatus ──────────────────────────────────────────────────────────
  group('updateStatus', () {
    test('не выдаёт неоплаченный заказ', () async {
      final created = await repo.createWithPayment(_orderData());
      await expectLater(() => repo.updateStatus(created.id, OrderStatus.completed), throwsA(isA<Exception>()));
      expect((await repo.findById(created.id))?.status, OrderStatus.pending);
    });

    test('не восстанавливает отменённый заказ', () async {
      final created = await repo.createWithPayment(_orderData());
      await repo.updateStatus(created.id, OrderStatus.cancelled);
      await expectLater(() => repo.updateStatus(created.id, OrderStatus.processing), throwsA(isA<Exception>()));
      expect((await repo.findById(created.id))?.status, OrderStatus.cancelled);
    });

    test('обновляет статус заказа', () async {
      final created = await repo.createWithPayment(_orderData());
      await markPaid(created.id);
      final updated = await repo.updateStatus(created.id, OrderStatus.completed);
      expect(updated?.status, OrderStatus.completed);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.updateStatus(999999, OrderStatus.cancelled), isNull);
    });
  });

  // ── getAllOrders ──────────────────────────────────────────────────────────
  group('getAllOrders', () {
    test('возвращает все заказы', () async {
      await repo.createWithPayment(_orderData());
      await repo.createWithPayment(_orderData());
      expect((await repo.getAllOrders()).length, 2);
    });

    test('фильтрует по статусу', () async {
      final order = await repo.createWithPayment(_orderData());
      await markPaid(order.id);
      await repo.updateStatus(order.id, OrderStatus.completed);
      final pending = await repo.getAllOrders(status: OrderStatus.pending);
      expect(pending.every((o) => o.status == OrderStatus.pending), isTrue);
    });

    test('limit ограничивает количество', () async {
      for (var i = 0; i < 5; i++) {
        await repo.createWithPayment(_orderData());
      }
      expect((await repo.getAllOrders(limit: 3)).length, 3);
    });
  });

  // ── deleteOrder ───────────────────────────────────────────────────────────
  group('deleteOrder', () {
    test('удаляет заказ', () async {
      final created = await repo.createWithPayment(_orderData());
      await repo.deleteOrder(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('возвращает null если заказ не найден', () async {
      expect(await repo.deleteOrder(999999), isNull);
    });
  });
}
