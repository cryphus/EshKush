import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PartnerStatisticsRepository.dart';
import 'package:backend/model/entities/PartnerStatistics.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PartnerStatisticsRepository repo;
  late int partnerId;
  late int pointId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PartnerStatisticsRepository(conn);
    final userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  setUp(() async => TestDb.truncate(conn, ['partner_statistics']));

  tearDownAll(() async => TestDb.close());

  PartnerStatistics _stats({
    int totalOrders = 0,
    double totalRevenue = 0.0,
    int totalCancel = 0,
    double averageRating = 0.0,
    int totalReviews = 0,
  }) =>
      PartnerStatistics(
        id: 0,
        partnerId: partnerId,
        pointId: pointId,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        totalCancel: totalCancel,
        averageRating: averageRating,
        totalReviews: totalReviews,
        createdAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт статистику с id > 0', () async {
      final result = await repo.create(_stats());
      expect(result.id, greaterThan(0));
      expect(result.partnerId, partnerId);
      expect(result.pointId, pointId);
    });

    test('сохраняет totalOrders и totalRevenue', () async {
      final result = await repo.create(_stats(totalOrders: 5, totalRevenue: 500.0));
      expect(result.totalOrders, 5);
      expect(result.totalRevenue, 500.0);
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает статистику по id', () async {
      final created = await repo.create(_stats(totalOrders: 3));
      final found = await repo.findById(created.id);
      expect(found?.totalOrders, 3);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByPartnerId ───────────────────────────────────────────────────────
  group('findByPartnerId', () {
    test('возвращает статистику по partnerId', () async {
      await repo.create(_stats(totalRevenue: 999.0));
      final found = await repo.findByPartnerId(partnerId);
      expect(found?.totalRevenue, 999.0);
    });

    test('возвращает null если нет данных', () async {
      expect(await repo.findByPartnerId(999999), isNull);
    });
  });

  // ── findByPointId ─────────────────────────────────────────────────────────
  group('findByPointId', () {
    test('возвращает статистику по pointId', () async {
      await repo.create(_stats(totalCancel: 2));
      final found = await repo.findByPointId(pointId);
      expect(found?.totalCancel, 2);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет поля статистики', () async {
      final created = await repo.create(_stats());
      final toUpdate = PartnerStatistics(
        id: created.id,
        partnerId: created.partnerId,
        pointId: created.pointId,
        totalOrders: 10,
        totalRevenue: 1000.0,
        totalCancel: 1,
        averageRating: 4.5,
        totalReviews: 5,
        createdAt: created.createdAt,
      );
      final updated = await repo.update(toUpdate);
      expect(updated.totalOrders, 10);
      expect(updated.totalRevenue, 1000.0);
      expect(updated.averageRating, 4.5);
    });

    test('бросает Exception если статистика не найдена', () async {
      final ghost = PartnerStatistics(
        id: 999999,
        partnerId: partnerId,
        pointId: pointId,
        totalOrders: 0,
        totalRevenue: 0,
        totalCancel: 0,
        createdAt: DateTime.now(),
      );
      expect(() => repo.update(ghost), throwsA(isA<Exception>()));
    });
  });

  // ── deactivate / activate ─────────────────────────────────────────────────
  group('deactivate / activate', () {
    test('deactivate не бросает исключений', () async {
      final created = await repo.create(_stats());
      await expectLater(repo.deactivate(created.id), completes);
    });

    test('activate не бросает исключений', () async {
      final created = await repo.create(_stats());
      await repo.deactivate(created.id);
      await expectLater(repo.activate(created.id), completes);
    });
  });
}
