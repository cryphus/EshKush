import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ActionLogRepository.dart';
import 'package:backend/model/entities/ActionLog.dart';
import 'package:backend/model/enums/ActionType.dart';
import 'package:backend/model/enums/EntityType.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late ActionLogRepository repo;
  late int userId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ActionLogRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['action_logs']));

  tearDownAll(() async => TestDb.close());

  ActionLog _log({
    ActionType actionType = ActionType.create,
    EntityType entityType = EntityType.user,
    int entityId = 1,
    String details = 'Действие выполнено',
  }) =>
      ActionLog(
        id: 0,
        userId: userId,
        actionType: actionType,
        targetEntity: entityType,
        targetId: entityId,
        details: details,
        timestamp: DateTime.now(),
        ipAddress: '127.0.0.1',
        isSuccess: true,
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт лог с id > 0', () async {
      final result = await repo.create(_log());
      expect(result.id, greaterThan(0));
      expect(result.userId, userId);
      expect(result.details, 'Действие выполнено');
    });

    test('сохраняет actionType', () async {
      final result = await repo.create(_log(actionType: ActionType.delete));
      expect(result.actionType, ActionType.delete);
    });

    test('сохраняет entityType', () async {
      final result = await repo.create(_log(entityType: EntityType.order));
      expect(result.targetEntity, EntityType.order);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает логи пользователя', () async {
      await repo.create(_log());
      await repo.create(_log(actionType: ActionType.update));
      expect((await repo.findByUserId(userId)).length, 2);
    });

    test('возвращает пустой список для пользователя без логов', () async {
      expect(await repo.findByUserId(999999), isEmpty);
    });
  });

  // ── findByEntity ──────────────────────────────────────────────────────────
  group('findByEntity', () {
    test('возвращает логи по entityType и entityId', () async {
      await repo.create(_log(entityType: EntityType.user, entityId: 1));
      await repo.create(_log(entityType: EntityType.user, entityId: 2));
      await repo.create(_log(entityType: EntityType.order, entityId: 1));

      final result = await repo.findByEntity(EntityType.user, 1);
      expect(result.length, 1);
      expect(result.first.targetEntity, EntityType.user);
    });

    test('возвращает пустой список если нет совпадений', () async {
      expect(await repo.findByEntity(EntityType.product, 99), isEmpty);
    });
  });

  // ── findByActionType ──────────────────────────────────────────────────────
  group('findByActionType', () {
    test('возвращает логи по actionType', () async {
      await repo.create(_log(actionType: ActionType.login));
      await repo.create(_log(actionType: ActionType.logout));
      final result = await repo.findByActionType(ActionType.login);
      expect(result.length, 1);
      expect(result.first.actionType, ActionType.login);
    });

    test('возвращает пустой список если нет совпадений', () async {
      expect(await repo.findByActionType(ActionType.search), isEmpty);
    });
  });

  // ── findRecent ────────────────────────────────────────────────────────────
  group('findRecent', () {
    test('возвращает не более limit записей', () async {
      for (var i = 0; i < 5; i++) {
        await repo.create(_log(details: 'Лог $i'));
      }
      expect((await repo.findRecent(limit: 3)).length, 3);
    });

    test('возвращает все если меньше limit', () async {
      await repo.create(_log());
      await repo.create(_log());
      expect((await repo.findRecent(limit: 100)).length, 2);
    });
  });
}
