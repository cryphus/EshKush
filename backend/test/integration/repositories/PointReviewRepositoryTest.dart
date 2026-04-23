import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/PointReviewRepository.dart';
import 'package:backend/model/entities/PointReview.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late PointReviewRepository repo;
  late int userId;
  late int pointId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = PointReviewRepository(conn);
    userId = await TestFixtures.createUser(conn);
    final cityId = await TestFixtures.createCity(conn);
    final partnerId = await TestFixtures.createPartner(conn, userId);
    pointId = await TestFixtures.createPoint(conn, cityId, partnerId);
  });

  setUp(() async => TestDb.truncate(conn, ['point_reviews']));

  tearDownAll(() async => TestDb.close());

  PointReview _review({double rating = 4.0, String comment = 'Хороший сервис'}) =>
      PointReview(
        id: 0,
        pointId: pointId,
        userId: userId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт отзыв с id > 0', () async {
      final result = await repo.create(_review());
      expect(result.id, greaterThan(0));
      expect(result.pointId, pointId);
      expect(result.userId, userId);
    });

    test('сохраняет rating и comment', () async {
      final result = await repo.create(_review(rating: 5.0, comment: 'Отлично!'));
      expect(result.rating, 5.0);
      expect(result.comment, 'Отлично!');
    });
  });

  // ── findById ──────────────────────────────────────────────────────────────
  group('findById', () {
    test('возвращает отзыв по id', () async {
      final created = await repo.create(_review());
      final found = await repo.findById(created.id);
      expect(found?.rating, 4.0);
    });

    test('возвращает null для несуществующего id', () async {
      expect(await repo.findById(999999), isNull);
    });
  });

  // ── findByPointId ─────────────────────────────────────────────────────────
  group('findByPointId', () {
    test('возвращает отзывы по pointId', () async {
      await repo.create(_review(rating: 3.0));
      await repo.create(_review(rating: 5.0));
      expect((await repo.findByPointId(pointId)).length, 2);
    });

    test('возвращает пустой список если нет отзывов', () async {
      expect(await repo.findByPointId(999999), isEmpty);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает отзывы пользователя', () async {
      await repo.create(_review());
      expect((await repo.findByUserId(userId)).length, 1);
    });
  });

  // ── update ────────────────────────────────────────────────────────────────
  group('update', () {
    test('обновляет rating', () async {
      final created = await repo.create(_review(rating: 3.0));
      final toUpdate = PointReview(
        id: created.id,
        pointId: created.pointId,
        userId: created.userId,
        rating: 5.0,
        comment: created.comment,
        createdAt: created.createdAt,
      );
      final updated = await repo.update(toUpdate);
      expect(updated.rating, 5.0);
    });

    test('бросает Exception если отзыв не найден', () async {
      final ghost = PointReview(
        id: 999999,
        pointId: pointId,
        userId: userId,
        rating: 4.0,
        comment: 'ghost',
        createdAt: DateTime.now(),
      );
      expect(() => repo.update(ghost), throwsA(isA<Exception>()));
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('удаляет отзыв', () async {
      final created = await repo.create(_review());
      await repo.delete(created.id);
      expect(await repo.findById(created.id), isNull);
    });

    test('бросает Exception если отзыв не найден', () async {
      expect(() => repo.delete(999999), throwsA(isA<Exception>()));
    });
  });
}
