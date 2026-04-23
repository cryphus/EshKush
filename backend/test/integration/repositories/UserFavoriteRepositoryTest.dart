import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/UserFavoriteRepository.dart';
import 'package:backend/model/entities/UserFavorite.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late UserFavoriteRepository repo;
  late int userId;
  late int pointId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = UserFavoriteRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  setUp(() async => TestDb.truncate(conn, ['user_favorites']));

  tearDownAll(() async => TestDb.close());

  UserFavorite _favorite() => UserFavorite(
        userId: userId,
        pointId: pointId,
        createdAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('добавляет точку в избранное', () async {
      final result = await repo.create(_favorite());
      expect(result.userId, userId);
      expect(result.pointId, pointId);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает избранное пользователя', () async {
      await repo.create(_favorite());
      expect((await repo.findByUserId(userId)).length, 1);
    });

    test('возвращает пустой список если избранного нет', () async {
      expect(await repo.findByUserId(999999), isEmpty);
    });
  });

  // ── findByPointId ─────────────────────────────────────────────────────────
  group('findByPointId', () {
    test('возвращает пользователей, добавивших точку в избранное', () async {
      await repo.create(_favorite());
      expect((await repo.findByPointId(pointId)).length, 1);
    });
  });

  // ── exists ────────────────────────────────────────────────────────────────
  group('exists', () {
    test('возвращает true если точка в избранном', () async {
      await repo.create(_favorite());
      expect(await repo.exists(userId, pointId), isTrue);
    });

    test('возвращает false если точки нет в избранном', () async {
      expect(await repo.exists(userId, pointId), isFalse);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет точку из избранного', () async {
      await repo.create(_favorite());
      await repo.delete(userId, pointId);
      expect(await repo.exists(userId, pointId), isFalse);
    });

    test('бросает Exception если записи нет', () async {
      expect(() => repo.delete(userId, pointId), throwsA(isA<Exception>()));
    });
  });
}
