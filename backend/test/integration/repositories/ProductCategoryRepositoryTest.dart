import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ProductCategoryRepository.dart';
import 'package:backend/model/entities/ProductCategory.dart';

import '../../helpers/TestDb.dart';

void main() {
  late PostgreSQLConnection conn;
  late ProductCategoryRepository repo;

  ProductCategory _cat({String name = 'Еда', String? desc}) =>
      ProductCategory(id: 0, name: name, createdAt: DateTime.now(), description: desc);

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ProductCategoryRepository(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['product_category_map', 'product_categories']));

  tearDownAll(() async => TestDb.close());

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт категорию продукта с id > 0', () async {
      final result = await repo.create(_cat(name: 'Напитки'));
      expect(result.id, greaterThan(0));
      expect(result.name, 'Напитки');
    });

    test('сохраняет description', () async {
      final result = await repo.create(_cat(name: 'Десерты', desc: 'Сладкое'));
      expect(result.description, 'Сладкое');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает категорию по id', () async {
      final created = await repo.create(_cat(name: 'Горячее'));
      final found = await repo.findById(created.id);
      expect(found?.name, 'Горячее');
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
    test('обновляет name и description', () async {
      final created = await repo.create(_cat(name: 'Old', desc: 'old desc'));
      final updated = await repo.update(
        ProductCategory(id: created.id, name: 'New', createdAt: created.createdAt, description: 'new desc'),
      );
      expect(updated.name, 'New');
      expect(updated.description, 'new desc');
    });

    test('бросает Exception если категория не найдена', () async {
      expect(
        () => repo.update(ProductCategory(id: 999999, name: 'Ghost', createdAt: DateTime.now())),
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
