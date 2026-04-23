import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PointRepository.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PointRepository repo;
  late int cityId;
  late int partnerId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PointRepository(conn);
    final userId = await TestFixtures.createUser(conn);
    cityId = await TestFixtures.createCity(conn);
    partnerId = await TestFixtures.createPartner(conn, userId);
  });

  setUp(() async => TestDb.truncate(conn, [
        'point_reviews',
        'point_category_map',
        'user_favorites',
        'order_history',
        'payment_transactions',
        'order_actions',
        'orders',
        'products',
        'points',
      ]));

  tearDownAll(() async => TestDb.close());

  Map<String, dynamic> _pointData({String name = 'TestPoint'}) => {
        'name': name,
        'address': 'ул. Тестовая, 1',
        'city_id': cityId,
        'products': <String, dynamic>{},
        'opening_hours': '09:00',
        'closing_hours': '21:00',
        'partner_id': partnerId,
        'longitude': 37.6176,
        'latitude': 55.7558,
        'tags': <String, dynamic>{},
      };

  // ── createPoint ───────────────────────────────────────────────────────────
  group('createPoint', () {
    test('создаёт точку с id > 0', () async {
      final result = await repo.createPoint(_pointData());
      expect(result.id, greaterThan(0));
      expect(result.name, 'TestPoint');
    });

    test('сохраняет city_id и partner_id', () async {
      final result = await repo.createPoint(_pointData());
      expect(result.cityId, cityId);
      expect(result.partnerId, partnerId);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает точку по id', () async {
      final created = await repo.createPoint(_pointData(name: 'Кофейня'));
      final found = await repo.findById(created.id);
      expect(found?.name, 'Кофейня');
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

    test('возвращает созданные точки', () async {
      await repo.createPoint(_pointData(name: 'P1'));
      await repo.createPoint(_pointData(name: 'P2'));
      expect((await repo.findAll()).length, 2);
    });

    test('limit ограничивает количество', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.createPoint(_pointData(name: 'Point$i'));
      }
      expect((await repo.findAll(limit: 3)).length, 3);
    });
  });

  // ── updatePoint ───────────────────────────────────────────────────────────
  group('updatePoint', () {
    test('обновляет name', () async {
      final created = await repo.createPoint(_pointData());
      final updated = await repo.updatePoint(created.id, {'name': 'НовоеНазвание'});
      expect(updated?.name, 'НовоеНазвание');
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.updatePoint(999999, {'name': 'ghost'}), isNull);
    });
  });

  // ── deletePoint ───────────────────────────────────────────────────────────
  group('deletePoint', () {
    test('удаляет точку', () async {
      final created = await repo.createPoint(_pointData());
      await repo.deletePoint(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.deletePoint(999999), isNull);
    });
  });
}
