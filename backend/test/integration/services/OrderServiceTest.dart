import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/PointRepository.dart';
import 'package:backend/repositories/ProductsRepository.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  if (!TestDb.isAvailable) {
    print('SKIP: TEST_DB_HOST не задан, пропуск интеграционных тестов OrderService');
    return;
  }

  late PostgreSQLConnection conn;
  late OrderService sut;
  late int userId;
  late int pointId;
  late int productId;

  setUpAll(() async {
    AppConfig.initForTesting();
    conn = await TestDb.connect();
    sut = OrderService(
      OrderRepository(conn),
      UserRepository(conn),
      PointRepository(conn),
      ProductsRepository(conn),
    );

    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);

    // Создаём продукт с известной ценой
    final res = await conn.query(
      '''
      INSERT INTO products (name, description, price, partner_id, point_id,
        weight, is_available, is_active, created_at)
      VALUES ('TestProd', 'desc', 50.0, @partnerId, @pointId,
        100.0, true, true, CURRENT_TIMESTAMP)
      RETURNING id
      ''',
      substitutionValues: {'partnerId': partnerId, 'pointId': pointId},
    );
    productId = res.first[0] as int;
  });

  setUp(() async => TestDb.truncate(conn, [
        'order_history',
        'payment_transactions',
        'order_actions',
        'orders',
      ]));

  tearDownAll(() async => TestDb.close());

  // ── createOrder ───────────────────────────────────────────────────────────
  group('createOrder', () {
    test('создаёт заказ и payment_transaction атомарно', () async {
      final order = await sut.createOrder({
        'user_id': userId,
        'point_id': pointId,
        'products_id': [productId],
        'total_price': 50.0,
        'partner_id': 1,
      });

      expect(order.id, greaterThan(0));
      expect(order.userId, userId);
      expect(order.totalPrice, 50.0);

      // Убеждаемся что payment_transaction тоже создалась
      final ptRows = await conn.query(
        'SELECT id FROM payment_transactions WHERE order_id = @orderId',
        substitutionValues: {'orderId': order.id},
      );
      expect(ptRows, hasLength(1));
    });

    test('бросает если пользователь не найден', () async {
      expect(
        () => sut.createOrder({
          'user_id': 999999,
          'point_id': pointId,
          'products_id': [productId],
          'total_price': 50.0,
          'partner_id': 1,
        }),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Пользователь не найден'),
        )),
      );
    });

    test('бросает если точка не найдена', () async {
      expect(
        () => sut.createOrder({
          'user_id': userId,
          'point_id': 999999,
          'products_id': [productId],
          'total_price': 50.0,
          'partner_id': 1,
        }),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Точка не найдена'),
        )),
      );
    });

    test('бросает если список продуктов пустой', () async {
      expect(
        () => sut.createOrder({
          'user_id': userId,
          'point_id': pointId,
          'products_id': [],
          'total_price': 0.0,
          'partner_id': 1,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает если сумма заказа не совпадает с суммой продуктов', () async {
      expect(
        () => sut.createOrder({
          'user_id': userId,
          'point_id': pointId,
          'products_id': [productId],
          'total_price': 999.99,
          'partner_id': 1,
        }),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Сумма заказа не соответствует'),
        )),
      );
    });
  });

  // ── getOrderById ──────────────────────────────────────────────────────────
  group('getOrderById', () {
    test('возвращает заказ по id', () async {
      final created = await sut.createOrder({
        'user_id': userId,
        'point_id': pointId,
        'products_id': [productId],
        'total_price': 50.0,
        'partner_id': 1,
      });

      final found = await sut.getOrderById(created.id);
      expect(found.id, created.id);
      expect(found.userId, userId);
    });

    test('бросает если заказ не найден', () async {
      expect(
        () => sut.getOrderById(999999),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Заказ не найден'),
        )),
      );
    });
  });
}
