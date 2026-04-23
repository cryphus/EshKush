import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PointService.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/repositories/PointRepository.dart';
import 'package:backend/model/entities/Point.dart';
import 'package:backend/model/entities/PointReview.dart';

import 'PointServiceTest.mocks.dart';

@GenerateMocks([PointRepository, CacheService])
void main() {
  late MockPointRepository pointRepo;
  late MockCacheService cache;
  late PointService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    pointRepo = MockPointRepository();
    cache     = MockCacheService();
    sut       = PointService(pointRepo, cache);

    when(cache.get(any)).thenAnswer((_) async => null);
    when(cache.set(any, any, ttl: anyNamed('ttl'))).thenAnswer((_) async => true);
    when(cache.delete(any)).thenAnswer((_) async => true);
    when(cache.deleteByPattern(any)).thenAnswer((_) async => 0);
    when(cache.isConnected).thenReturn(true);
  });

  // ────────────────────────────────────────────────────────── fixtures ──────
  Point _point({int id = 1, String name = 'Test Point'}) => Point(
    id: id, name: name, address: 'ул. Пушкина 1', cityId: 1,
    products: {}, openingHours: '09:00', closingHours: '21:00',
    partnerId: 1, longitude: 37.6, latitude: 55.7,
    tags: {}, createdAt: DateTime(2024),
  );

  PointReview _review() => PointReview(
    id: 1, pointId: 1, userId: 1,
    createdAt: DateTime(2024), rating: 4.0,
  );

  // ── getPointById ──────────────────────────────────────────────────────────
  group('getPointById', () {
    test('кеш-хит: возвращает из кеша без вызова репозитория', () async {
      when(cache.get(any)).thenAnswer((_) async => _point());
      final result = await sut.getPointById(1);
      expect(result.id, 1);
      verifyNever(pointRepo.findById(any));
    });

    test('кеш-промах: загружает из БД и кеширует результат', () async {
      when(pointRepo.findById(1)).thenAnswer((_) async => _point());
      final result = await sut.getPointById(1);
      expect(result.id, 1);
      verify(cache.set(any, any, ttl: anyNamed('ttl'))).called(1);
    });

    test('бросает если точка не найдена в БД', () async {
      when(pointRepo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getPointById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getAllPoints ──────────────────────────────────────────────────────────
  group('getAllPoints', () {
    test('дефолтные параметры: использует кеш', () async {
      when(pointRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_point(id: 1), _point(id: 2)]);
      final result = await sut.getAllPoints();
      expect(result.length, 2);
      verify(cache.set(any, any, ttl: anyNamed('ttl'))).called(1);
    });

    test('кастомные параметры: не кешируется', () async {
      when(pointRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [_point()]);
      final result = await sut.getAllPoints(limit: 5, offset: 10);
      expect(result.length, 1);
      verifyNever(cache.set(any, any, ttl: anyNamed('ttl')));
    });

    test('кеш-хит при дефолтных параметрах: не обращается к БД', () async {
      when(cache.get(any)).thenAnswer((_) async => [_point().toJson()]);
      await sut.getAllPoints();
      verifyNever(pointRepo.findAll(limit: anyNamed('limit'), offset: anyNamed('offset')));
    });
  });

  // ── createPoint ───────────────────────────────────────────────────────────
  group('createPoint', () {
    test('бросает если name пустой', () {
      expect(
        () => sut.createPoint({'name': '', 'address': 'addr', 'city_id': 1, 'partner_id': 1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если address пустой', () {
      expect(
        () => sut.createPoint({'name': 'Test', 'address': '', 'city_id': 1, 'partner_id': 1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если city_id <= 0', () {
      expect(
        () => sut.createPoint({'name': 'Test', 'address': 'addr', 'city_id': 0, 'partner_id': 1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает при некорректной долготе (> 180)', () {
      expect(
        () => sut.createPoint({'name': 'Test', 'address': 'addr', 'longitude': 200.0}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает при некорректной широте (< -90)', () {
      expect(
        () => sut.createPoint({'name': 'Test', 'address': 'addr', 'latitude': -100.0}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно создаёт и инвалидирует кеш', () async {
      when(pointRepo.createPoint(any)).thenAnswer((_) async => _point());
      final result = await sut.createPoint({'name': 'New Point', 'address': 'addr'});
      expect(result.id, 1);
      verify(cache.delete(any)).called(greaterThan(0));
    });
  });

  // ── updatePoint ───────────────────────────────────────────────────────────
  group('updatePoint', () {
    test('бросает если точка не найдена', () async {
      when(pointRepo.updatePoint(99, any)).thenAnswer((_) async => null);
      expect(
        () => sut.updatePoint(99, {'name': 'Updated'}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно обновляет и инвалидирует кеш', () async {
      when(pointRepo.updatePoint(1, any)).thenAnswer((_) async => _point(name: 'Updated'));
      final result = await sut.updatePoint(1, {'name': 'Updated'});
      expect(result.name, 'Updated');
      verify(cache.delete(any)).called(greaterThan(0));
    });
  });

  // ── deletePoint ───────────────────────────────────────────────────────────
  group('deletePoint', () {
    test('бросает если точка не найдена', () async {
      when(pointRepo.deletePoint(99)).thenAnswer((_) async => null);
      expect(() => sut.deletePoint(99), throwsA(isA<Exception>()));
    });

    test('успешно удаляет и инвалидирует кеш', () async {
      when(pointRepo.deletePoint(1)).thenAnswer((_) async => _point());
      await expectLater(sut.deletePoint(1), completes);
      verify(cache.delete(any)).called(greaterThan(0));
    });
  });

  // ── updateRating ──────────────────────────────────────────────────────────
  group('updateRating', () {
    test('бросает при рейтинге < 0', () async {
      expect(() => sut.updateRating(1, -0.1), throwsA(isA<Exception>()));
    });

    test('бросает при рейтинге > 5', () async {
      expect(() => sut.updateRating(1, 5.1), throwsA(isA<Exception>()));
    });

    test('граница: рейтинг 0 допустим', () async {
      when(pointRepo.updateRating(1, 0)).thenAnswer((_) async => _point());
      await expectLater(sut.updateRating(1, 0), completes);
    });

    test('граница: рейтинг 5 допустим', () async {
      when(pointRepo.updateRating(1, 5)).thenAnswer((_) async => _point());
      await expectLater(sut.updateRating(1, 5), completes);
    });

    test('бросает если точка не найдена', () async {
      when(pointRepo.updateRating(99, any)).thenAnswer((_) async => null);
      expect(() => sut.updateRating(99, 4.0), throwsA(isA<Exception>()));
    });
  });

  // ── getPointReviews / createPointReview ───────────────────────────────────
  group('getPointReviews', () {
    test('возвращает список отзывов', () async {
      when(pointRepo.getPointReviews(1)).thenAnswer((_) async => [_review()]);
      final result = await sut.getPointReviews(1);
      expect(result.length, 1);
    });

    test('возвращает пустой список', () async {
      when(pointRepo.getPointReviews(1)).thenAnswer((_) async => []);
      expect(await sut.getPointReviews(1), isEmpty);
    });
  });

  group('createPointReview', () {
    test('успешно создаёт отзыв', () async {
      when(pointRepo.createPointReview(any)).thenAnswer((_) async => _review());
      final result = await sut.createPointReview({'point_id': 1, 'user_id': 1, 'rating': 4.0});
      expect(result.rating, 4.0);
    });
  });
}