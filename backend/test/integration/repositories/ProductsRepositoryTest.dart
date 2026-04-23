import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/ProductsRepository.dart';
import 'package:backend/model/entities/Product.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late ProductsRepository repo;
  late int pointId;
  late int partnerId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = ProductsRepository(conn);
    final userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  setUp(() async => TestDb.truncate(conn, ['product_category_map', 'products']));

  tearDownAll(() async => TestDb.close());

  Map<String, dynamic> _productData({String name = 'TestProduct', double price = 99.0}) => {
        'name': name,
        'description': 'Test Description',
        'price': price,
        'point_id': pointId,
        'partner_id': partnerId,
        'weight': 0.5,
        'is_available': true,
        'is_active': true,
      };

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт продукт с id > 0', () async {
      final result = await repo.create(_productData());
      expect(result.id, greaterThan(0));
      expect(result.name, 'TestProduct');
    });

    test('сохраняет price и weight', () async {
      final result = await repo.create(_productData(price: 199.0));
      expect(result.price, 199.0);
      expect(result.weight, 0.5);
    });

    test('is_available и is_active по умолчанию true', () async {
      final result = await repo.create(_productData());
      expect(result.isAvailable, isTrue);
      expect(result.isActive, isTrue);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает продукт по id', () async {
      final created = await repo.create(_productData(name: 'Кофе'));
      final found = await repo.findById(created.id);
      expect(found?.name, 'Кофе');
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

    test('возвращает созданные продукты', () async {
      await repo.create(_productData(name: 'P1'));
      await repo.create(_productData(name: 'P2'));
      expect((await repo.findAll()).length, 2);
    });

    test('limit ограничивает количество', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.create(_productData(name: 'Prod$i'));
      }
      expect((await repo.findAll(limit: 3)).length, 3);
    });
  });

  // ── findByPointId ─────────────────────────────────────────────────────────
  group('findByPointId', () {
    test('возвращает продукты по pointId', () async {
      await repo.create(_productData(name: 'A'));
      await repo.create(_productData(name: 'B'));
      final result = await repo.findByPointId(pointId);
      expect(result.length, 2);
    });

    test('возвращает пустой список если нет продуктов', () async {
      expect(await repo.findByPointId(999999), isEmpty);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет name и price', () async {
      final created = await repo.create(_productData());
      final toUpdate = Product(
        id: created.id,
        name: 'ОбновлённыйПродукт',
        description: created.description,
        price: 299.0,
        imageUrl: created.imageUrl,
        partnerId: created.partnerId,
        pointId: created.pointId,
        weight: created.weight,
        isAvailable: created.isAvailable,
        isActive: created.isActive,
        createdAt: created.createdAt,
      );
      final updated = await repo.update(toUpdate);
      expect(updated.name, 'ОбновлённыйПродукт');
      expect(updated.price, 299.0);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет продукт', () async {
      final created = await repo.create(_productData());
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });
  });
}
