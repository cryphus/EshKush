import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ChangesRepository.dart';
import 'package:backend/model/entities/Changes.dart';
import 'package:backend/model/enums/EntityType.dart';
import 'package:backend/model/enums/ChangeType.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late ChangesRepository repo;
  late int userId;

  /// entityType и changeType — строки (поля Changes), но значения должны
  /// совпадать с именами enum (entity_type, change_type в БД).
  Changes _change({
    String entityType = 'user',
    int entityId = 1,
    String changeType = 'update',
    String fieldName = 'username',
    String oldValue = 'old_name',
    String newValue = 'new_name',
  }) =>
      Changes(
        id: 0,
        entityType: entityType,
        entityId: entityId,
        changeType: changeType,
        fieldName: fieldName,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: DateTime.now(),
      );

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ChangesRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['changes']));

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт запись с id > 0', () async {
      final result = await repo.create(_change());
      expect(result.id, greaterThan(0));
      expect(result.fieldName, 'username');
      expect(result.oldValue, 'old_name');
      expect(result.newValue, 'new_name');
    });

    test('isReverted по умолчанию false', () async {
      final result = await repo.create(_change());
      expect(result.isReverted, isFalse);
    });

    test('сохраняет разные changeType', () async {
      final r1 = await repo.create(_change(changeType: 'create', oldValue: 'null', newValue: 'created'));
      final r2 = await repo.create(_change(changeType: 'delete', oldValue: 'exists', newValue: 'deleted'));
      expect(r1.changeType, 'create');
      expect(r2.changeType, 'delete');
    });
  });

  // ── findByEntity ──────────────────────────────────────────────────────────
  group('findByEntity', () {
    test('возвращает изменения по entityType и entityId', () async {
      await repo.create(_change(entityType: 'user', entityId: 1));
      await repo.create(_change(entityType: 'user', entityId: 2, oldValue: 'a', newValue: 'b'));
      await repo.create(_change(entityType: 'order', entityId: 1, oldValue: 'x', newValue: 'y'));

      final result = await repo.findByEntity(EntityType.user, 1);
      expect(result.length, 1);
      expect(result.first.entityId, 1);
    });

    test('возвращает пустой список если нет совпадений', () async {
      expect(await repo.findByEntity(EntityType.product, 99), isEmpty);
    });
  });

  // ── findByChangeType ──────────────────────────────────────────────────────
  group('findByChangeType', () {
    test('возвращает только записи с заданным changeType', () async {
      await repo.create(_change(changeType: 'update'));
      await repo.create(_change(changeType: 'delete', oldValue: 'v', newValue: 'gone'));
      final updates = await repo.findByChangeType(ChangeType.update);
      expect(updates.length, 1);
      expect(updates.first.changeType, 'update');
    });

    test('возвращает пустой список если нет совпадений', () async {
      expect(await repo.findByChangeType(ChangeType.restore), isEmpty);
    });
  });

  // ── findRecent ────────────────────────────────────────────────────────────
  group('findRecent', () {
    test('возвращает не более limit записей', () async {
      for (var i = 0; i < 5; i++) {
        await repo.create(_change(oldValue: 'v$i', newValue: 'n$i'));
      }
      expect((await repo.findRecent(limit: 3)).length, 3);
    });

    test('возвращает все если меньше limit', () async {
      await repo.create(_change());
      await repo.create(_change(oldValue: 'x', newValue: 'y'));
      expect((await repo.findRecent(limit: 100)).length, 2);
    });
  });

  // ── revertChange ──────────────────────────────────────────────────────────
  group('revertChange', () {
    test('помечает изменение как откатанное', () async {
      final created = await repo.create(_change());
      await repo.revertChange(created.id, userId);
      final all = await repo.findRecent();
      final reverted = all.firstWhere((c) => c.id == created.id);
      expect(reverted.isReverted, isTrue);
    });

    test('сохраняет комментарий при откате', () async {
      final created = await repo.create(_change());
      await repo.revertChange(created.id, userId, comment: 'Ошибочное изменение');
      final all = await repo.findRecent();
      final reverted = all.firstWhere((c) => c.id == created.id);
      expect(reverted.comment, 'Ошибочное изменение');
    });
  });
}
