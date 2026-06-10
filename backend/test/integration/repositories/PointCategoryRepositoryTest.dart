import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PointCategoryRepository.dart';
import 'package:backend/model/entities/PointCategory.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late PointCategoryRepository repo;

  PointCategory _cat({String name = 'Кафе', String? desc}) =>
      PointCategory(id: 0, name: name, createdAt: DateTime.now(), description: desc);

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PointCategoryRepository(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['point_category_map', 'point_categories']));

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт категорию и возвращает с id > 0', () async {
      final result = await repo.create(_cat(name: 'Ресторан'));
      expect(result.id, greaterThan(0));
      expect(result.name, 'Ресторан');
    });

    test('сохраняет описание если передано', () async {
      final result = await repo.create(_cat(name: 'Магазин', desc: 'Торговая точка'));
      expect(result.description, 'Торговая точка');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает категорию по id', () async {
      final created = await repo.create(_cat(name: 'Кафе'));
      final found = await repo.findById(created.id);
      expect(found?.name, 'Кафе');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findAll ───────────────────────────────────────────────────────────────
  group('findAll', () {
    test('возвращает пустой список', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('возвращает все категории', () async {
      await repo.create(_cat(name: 'А'));
      await repo.create(_cat(name: 'Б'));
      expect((await repo.findAll()).length, 2);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет name', () async {
      final created = await repo.create(_cat(name: 'Старое'));
      final updated = await repo.update(created.id, {'name': 'Новое'});
      expect(updated.name, 'Новое');
    });

    test('обновляет description', () async {
      final created = await repo.create(_cat(name: 'Тест'));
      final updated =
          await repo.update(created.id, {'description': 'Обновлённое описание'});
      expect(updated.description, 'Обновлённое описание');
    });

    test('бросает если нет полей для обновления', () async {
      final created = await repo.create(_cat(name: 'X'));
      expect(
        () => repo.update(created.id, {}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает Exception если категория не найдена', () async {
      expect(
        () => repo.update(999999, {'name': 'Ghost'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет категорию', () async {
      final created = await repo.create(_cat(name: 'ToDelete'));
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если категория не найдена', () async {
      expect(
        () => repo.delete(999999),
        throwsA(isA<Exception>()),
      );
    });
  });
}
