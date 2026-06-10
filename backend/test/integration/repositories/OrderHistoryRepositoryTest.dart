import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/OrderHistoryRepository.dart';
import 'package:backend/model/entities/OrderHistory.dart';
import 'package:backend/model/enums/HistoryStatus.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late OrderHistoryRepository repo;
  late int userId;
  late int pointId;
  late int orderId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = OrderHistoryRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
    orderId = await TestFixtures.createOrder(conn, userId, pointId);
  });

  setUp(() async => TestDb.truncate(conn, ['order_history']));

  tearDownAll(() async => TestDb.close());

  final _now = DateTime.now();

  OrderHistory _history({
    HistoryStatus status = HistoryStatus.pending,
    double totalSum = 200.0,
  }) =>
      OrderHistory(
        id: 0,
        orderId: orderId,
        pointId: pointId,
        userId: userId,
        orderDate: _now,
        totalSum: totalSum,
        status: status,
        createdAt: _now,
        updatedAt: _now,
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт запись с id > 0', () async {
      final result = await repo.create(_history());
      expect(result.id, greaterThan(0));
      expect(result.orderId, orderId);
      expect(result.userId, userId);
    });

    test('сохраняет статус и totalSum', () async {
      final result = await repo.create(_history(status: HistoryStatus.completed, totalSum: 350.0));
      expect(result.status, HistoryStatus.completed);
      expect(result.totalSum, 350.0);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает запись по id', () async {
      final created = await repo.create(_history());
      final found = await repo.findById(created.id);
      expect(found?.orderId, orderId);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает историю пользователя', () async {
      await repo.create(_history());
      await repo.create(_history());
      expect((await repo.findByUserId(userId)).length, 2);
    });

    test('возвращает пустой список если истории нет', () async {
      expect(await repo.findByUserId(999999), isEmpty);
    });
  });

  // ── findByPointId ─────────────────────────────────────────────────────────
  group('findByPointId', () {
    test('возвращает историю по pointId', () async {
      await repo.create(_history());
      expect((await repo.findByPointId(pointId)).length, 1);
    });
  });

  // ── getByStatus ───────────────────────────────────────────────────────────
  group('getByStatus', () {
    test('возвращает только записи с заданным статусом', () async {
      await repo.create(_history(status: HistoryStatus.pending));
      await repo.create(_history(status: HistoryStatus.completed));
      final pending = await repo.getByStatus(HistoryStatus.pending);
      expect(pending.every((h) => h.status == HistoryStatus.pending), isTrue);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет статус', () async {
      final created = await repo.create(_history(status: HistoryStatus.pending));
      final toUpdate = OrderHistory(
        id: created.id,
        orderId: created.orderId,
        pointId: created.pointId,
        userId: created.userId,
        orderDate: created.orderDate,
        totalSum: created.totalSum,
        status: HistoryStatus.completed,
        createdAt: created.createdAt,
        updatedAt: DateTime.now(),
      );
      final updated = await repo.update(toUpdate);
      expect(updated.status, HistoryStatus.completed);
    });

    test('бросает Exception если запись не найдена', () async {
      final ghost = OrderHistory(
        id: 999999,
        orderId: orderId,
        pointId: pointId,
        userId: userId,
        orderDate: _now,
        totalSum: 0,
        status: HistoryStatus.pending,
        createdAt: _now,
        updatedAt: _now,
      );
      expect(() => repo.update(ghost), throwsA(isA<Exception>()));
    });
  });
}
