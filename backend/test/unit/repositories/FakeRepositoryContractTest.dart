/// Контрактные тесты репозиториев через Fake-реализации.
///
/// Проверяют бизнес-контракт (CRUD, фильтрация, пагинация, rollback),
/// не делая реальных SQL-запросов. Это позволяет протестировать
/// семантику репозиториев без запущенной БД.
import 'package:test/test.dart';
import 'package:backend/model/entities/Order.dart';
import 'package:backend/model/entities/User.dart';
import 'package:backend/model/enums/OrderStatus.dart';
import 'package:backend/model/enums/UserRole.dart';

import '../../helpers/FakeOrderRepo.dart';
import '../../helpers/FakeUserRepo.dart';

void main() {
  // ────────────────────────────────────── FakeOrderRepository ───────────────
  group('FakeOrderRepository', () {
    late FakeOrderRepository repo;

    Order _order({
      int id = 1,
      OrderStatus status = OrderStatus.pending,
      double price = 100.0,
    }) =>
        Order(
          id: id, productsId: [1], userId: 1, pointId: 1,
          date: DateTime(2024), totalPrice: price,
          createdAt: DateTime(2024), status: status,
        );

    setUp(() {
      repo = FakeOrderRepository();
    });

    // ── findById ──────────────────────────────────────────────────────────
    group('findById', () {
      test('возвращает заказ если он есть', () async {
        repo.seed(_order(id: 5));
        final result = await repo.findById(5);
        expect(result?.id, 5);
      });

      test('возвращает null если заказа нет', () async {
        final result = await repo.findById(999);
        expect(result, isNull);
      });
    });

    // ── getAllOrders ───────────────────────────────────────────────────────
    group('getAllOrders', () {
      setUp(() {
        repo.seed(_order(id: 1, status: OrderStatus.pending));
        repo.seed(_order(id: 2, status: OrderStatus.completed));
        repo.seed(_order(id: 3, status: OrderStatus.pending));
      });

      test('без фильтра: возвращает все заказы', () async {
        final result = await repo.getAllOrders();
        expect(result.length, 3);
      });

      test('фильтрация по статусу pending', () async {
        final result = await repo.getAllOrders(status: OrderStatus.pending);
        expect(result.length, 2);
        expect(result.every((o) => o.status == OrderStatus.pending), isTrue);
      });

      test('фильтрация по статусу completed', () async {
        final result = await repo.getAllOrders(status: OrderStatus.completed);
        expect(result.length, 1);
        expect(result.first.id, 2);
      });

      test('пагинация: limit', () async {
        final result = await repo.getAllOrders(limit: 2);
        expect(result.length, 2);
      });

      test('пагинация: offset', () async {
        final result = await repo.getAllOrders(limit: 10, offset: 2);
        expect(result.length, 1);
      });

      test('limit=0 возвращает пустой список', () async {
        final result = await repo.getAllOrders(limit: 0);
        expect(result, isEmpty);
      });

      test('offset за пределами — пустой список', () async {
        final result = await repo.getAllOrders(offset: 100);
        expect(result, isEmpty);
      });
    });

    // ── createWithPayment ─────────────────────────────────────────────────
    group('createWithPayment', () {
      test('возвращает созданный заказ', () async {
        repo.nextCreated = _order(id: 10);
        final result = await repo.createWithPayment({'user_id': 1});
        expect(result.id, 10);
      });

      test('rollback: исключение пробрасывается наружу', () async {
        repo.throwOnCreate = true;
        repo.createError = 'DB rollback: unique constraint';
        expect(
          () => repo.createWithPayment({'user_id': 1}),
          throwsA(isA<Exception>()
              .having((e) => e.toString(), 'message', contains('DB rollback'))),
        );
      });

      test('rollback с разными сообщениями', () async {
        repo.throwOnCreate = true;
        repo.createError = 'foreign key violation';
        expect(
          () => repo.createWithPayment({}),
          throwsA(isA<Exception>()
              .having((e) => e.toString(), 'message', contains('foreign key'))),
        );
      });
    });

    // ── updateStatus ──────────────────────────────────────────────────────
    group('updateStatus', () {
      test('обновляет статус существующего заказа', () async {
        repo.seed(_order(id: 1, status: OrderStatus.pending));
        final result = await repo.updateStatus(1, OrderStatus.completed);
        expect(result?.status, OrderStatus.completed);
      });

      test('возвращает null если заказ не найден', () async {
        final result = await repo.updateStatus(999, OrderStatus.completed);
        expect(result, isNull);
      });

      test('изменение статуса не меняет другие поля', () async {
        repo.seed(_order(id: 1, price: 250.0));
        final result = await repo.updateStatus(1, OrderStatus.completed);
        expect(result?.totalPrice, 250.0);
        expect(result?.userId, 1);
      });
    });

    // ── deleteOrder ───────────────────────────────────────────────────────
    group('deleteOrder', () {
      test('удаляет заказ и возвращает его', () async {
        repo.seed(_order(id: 1));
        final result = await repo.deleteOrder(1);
        expect(result?.id, 1);
        expect(await repo.findById(1), isNull);
      });

      test('возвращает null если заказ не существует', () async {
        final result = await repo.deleteOrder(999);
        expect(result, isNull);
      });

      test('удаление одного заказа не влияет на другие', () async {
        repo.seed(_order(id: 1));
        repo.seed(_order(id: 2));
        await repo.deleteOrder(1);
        expect(await repo.findById(2), isNotNull);
      });
    });
  });

  // ────────────────────────────────────── FakeUserRepository ────────────────
  group('FakeUserRepository', () {
    late FakeUserRepository repo;

    setUp(() {
      repo = FakeUserRepository();
    });

    // ── findById ──────────────────────────────────────────────────────────
    group('findById', () {
      test('возвращает пользователя если существует', () async {
        final user = makeUser(id: 1, username: 'alice');
        repo.seed(user);
        final result = await repo.findById(1);
        expect(result?.username, 'alice');
      });

      test('возвращает null если не найден', () async {
        expect(await repo.findById(999), isNull);
      });
    });

    // ── findByUsername ────────────────────────────────────────────────────
    group('findByUsername', () {
      test('находит по username', () async {
        repo.seed(makeUser(id: 1, username: 'bob'));
        final result = await repo.findByUsername('bob');
        expect(result?.id, 1);
      });

      test('возвращает null для несуществующего username', () async {
        expect(await repo.findByUsername('nobody'), isNull);
      });
    });

    // ── authenticate ──────────────────────────────────────────────────────
    group('authenticate', () {
      test('возвращает пользователя если username совпадает (fake не проверяет пароль)', () async {
        repo.seed(makeUser(id: 1, username: 'carol'));
        final result = await repo.authenticate('carol', 'any_password');
        expect(result?.username, 'carol');
      });

      test('возвращает null если username не найден', () async {
        final result = await repo.authenticate('unknown', 'pass');
        expect(result, isNull);
      });
    });

    // ── createUser ────────────────────────────────────────────────────────
    group('createUser', () {
      test('создаёт пользователя и присваивает id', () async {
        final user = await repo.createUser({
          'username': 'dave',
          'email': 'dave@example.com',
          'number': '+79001234567',
        });
        expect(user.username, 'dave');
        expect(user.id, greaterThan(0));
      });

      test('созданный пользователь доступен через findByUsername', () async {
        await repo.createUser({
          'username': 'eve',
          'email': 'eve@example.com',
          'number': '+79001234567',
        });
        final found = await repo.findByUsername('eve');
        expect(found?.username, 'eve');
      });

      test('роль по умолчанию — user', () async {
        final user = await repo.createUser({
          'username': 'frank',
          'email': 'frank@example.com',
          'number': '+79001234567',
        });
        expect(user.role, UserRole.user);
      });

      test('ID инкрементируется при создании нескольких пользователей', () async {
        final u1 = await repo.createUser({'username': 'user_one', 'email': 'u1@e.com', 'number': '+79001234567'});
        final u2 = await repo.createUser({'username': 'user_two', 'email': 'u2@e.com', 'number': '+79001234568'});
        expect(u2.id, greaterThan(u1.id));
      });
    });

    // ── изоляция между тестами ────────────────────────────────────────────
    group('изоляция', () {
      test('каждый тест начинает с пустым репозиторием', () async {
        expect(await repo.findByUsername('alice'), isNull);
      });

      test('seed добавляет данные доступные в тесте', () async {
        repo.seed(makeUser(id: 42, username: 'seeded'));
        expect(await repo.findById(42), isNotNull);
      });
    });
  });
}
