import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:backend/model/entities/PaymentTransactions.dart';
import 'package:backend/model/enums/PaymentMethod.dart';
import 'package:backend/model/enums/PaymentTransactionStatus.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PaymentTransactionsRepository repo;
  late int userId;
  late int pointId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PaymentTransactionsRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  /// Каждый тест создаёт заказ (и связанный платёж) сам, а setUp очищает обе таблицы.
  setUp(() async => TestDb.truncate(conn, ['payment_transactions', 'order_history', 'order_actions', 'orders']));

  tearDownAll(() async => TestDb.close());

  /// Создаёт заказ + платёж и возвращает orderId и первый PaymentTransactions.
  Future<({int orderId, PaymentTransactions pt})> _setup({double price = 300.0}) async {
    final oid = await TestFixtures.createOrder(conn, userId, pointId, totalPrice: price);
    final pts = await repo.findByOrderId(oid);
    return (orderId: oid, pt: pts.first);
  }

  PaymentTransactions _newTransaction(int orderId, {
    double orderPrice = 100.0,
    PaymentMethod method = PaymentMethod.other,
    PaymentTransactionStatus status = PaymentTransactionStatus.pending,
  }) =>
      PaymentTransactions(
        id: 0,
        orderId: orderId,
        providerTransactionId: orderId.toString(),
        orderPrice: orderPrice,
        transactionDate: DateTime.now(),
        paymentMethod: method,
        status: status,
        isActive: true,
      );

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает транзакцию по id', () async {
      final setup = await _setup();
      final found = await repo.findById(setup.pt.id);
      expect(found?.orderId, setup.orderId);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByOrderId ─────────────────────────────────────────────────────────
  group('findByOrderId', () {
    test('возвращает транзакции по orderId', () async {
      final setup = await _setup();
      final result = await repo.findByOrderId(setup.orderId);
      expect(result.length, 1);
      expect(result.first.orderId, setup.orderId);
    });

    test('возвращает пустой список если нет транзакций', () async {
      expect(await repo.findByOrderId(999999), isEmpty);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает транзакции пользователя через JOIN', () async {
      await _setup();
      await _setup();
      expect((await repo.findByUserId(userId)).length, 2);
    });
  });

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт транзакцию с id > 0', () async {
      final setup = await _setup();
      // Удаляем авто-созданную транзакцию, чтобы создать новую вручную
      await conn.execute(
        'DELETE FROM payment_transactions WHERE order_id = @id',
        substitutionValues: {'id': setup.orderId},
      );
      final result = await repo.create(_newTransaction(setup.orderId, orderPrice: 500.0));
      expect(result.id, greaterThan(0));
      expect(result.orderId, setup.orderId);
      expect(result.orderPrice, 500.0);
    });
  });

  // ── deactivate / activate ─────────────────────────────────────────────────
  group('deactivate / activate', () {
    test('deactivate переводит is_active в false', () async {
      final setup = await _setup();
      await repo.deactivate(setup.pt.id);
      final found = await repo.findById(setup.pt.id);
      expect(found?.isActive, isFalse);
    });

    test('activate переводит is_active в true', () async {
      final setup = await _setup();
      await repo.deactivate(setup.pt.id);
      await repo.activate(setup.pt.id);
      final found = await repo.findById(setup.pt.id);
      expect(found?.isActive, isTrue);
    });
  });

  // ── findByDateRange ───────────────────────────────────────────────────────
  group('findByDateRange', () {
    test('возвращает транзакции в диапазоне дат', () async {
      await _setup();
      final start = DateTime.now().subtract(const Duration(minutes: 5));
      final end = DateTime.now().add(const Duration(minutes: 5));
      expect((await repo.findByDateRange(start, end)).length, greaterThan(0));
    });
  });
}
