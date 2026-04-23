import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/OrderActionsRepository.dart';
import 'package:backend/model/entities/OrderActions.dart';
import 'package:backend/model/enums/ActionType.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late OrderActionsRepository repo;
  late int userId;
  late int pointId;
  late int partnerId;
  late int orderId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = OrderActionsRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
    orderId = await TestFixtures.createOrder(conn, userId, pointId);
  });

  setUp(() async => TestDb.truncate(conn, ['order_actions']));

  tearDownAll(() async => TestDb.close());

  final _now = DateTime.now();

  OrderActions _action({
    ActionType type = ActionType.create,
    String description = 'Тестовое действие',
  }) =>
      OrderActions(
        id: 0,
        orderId: orderId,
        actionType: type,
        description: description,
        createdAt: _now,
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт действие с id > 0', () async {
      final result = await repo.create(_action());
      expect(result.id, greaterThan(0));
      expect(result.orderId, orderId);
    });

    test('сохраняет actionType', () async {
      final result = await repo.create(_action(type: ActionType.update));
      expect(result.actionType, ActionType.update);
    });

    test('сохраняет description', () async {
      final result = await repo.create(_action(description: 'Кастомное действие'));
      expect(result.description, 'Кастомное действие');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает действие по id', () async {
      final created = await repo.create(_action());
      final found = await repo.findById(created.id);
      expect(found?.orderId, orderId);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByOrderId ─────────────────────────────────────────────────────────
  group('findByOrderId', () {
    test('возвращает действия по orderId', () async {
      await repo.create(_action());
      await repo.create(_action(type: ActionType.update));
      expect((await repo.findByOrderId(orderId)).length, 2);
    });

    test('возвращает пустой список если нет действий', () async {
      expect(await repo.findByOrderId(999999), isEmpty);
    });
  });

  // ── findByPartnerId ───────────────────────────────────────────────────────
  group('findByPartnerId', () {
    test('возвращает действия по partnerId через JOIN', () async {
      await repo.create(_action());
      expect((await repo.findByPartnerId(partnerId)).length, 1);
    });

    test('возвращает пустой список для неизвестного партнёра', () async {
      expect(await repo.findByPartnerId(999999), isEmpty);
    });
  });

  // ── getByActionType ───────────────────────────────────────────────────────
  group('getByActionType', () {
    test('возвращает действия заданного типа', () async {
      await repo.create(_action(type: ActionType.create));
      await repo.create(_action(type: ActionType.delete));
      final result = await repo.getByActionType(ActionType.create);
      expect(result.every((a) => a.actionType == ActionType.create), isTrue);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет actionType', () async {
      final created = await repo.create(_action(type: ActionType.create));
      final toUpdate = OrderActions(
        id: created.id,
        orderId: created.orderId,
        actionType: ActionType.delete,
        description: created.description,
        createdAt: created.createdAt,
      );
      final updated = await repo.update(toUpdate);
      expect(updated.actionType, ActionType.delete);
    });

    test('бросает Exception если действие не найдено', () async {
      final ghost = OrderActions(
        id: 999999,
        orderId: orderId,
        actionType: ActionType.other,
        createdAt: _now,
      );
      expect(() => repo.update(ghost), throwsA(isA<Exception>()));
    });
  });
}
