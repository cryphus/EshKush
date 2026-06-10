import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PartnerStatisticsService.dart';
import 'package:backend/repositories/PartnerStatisticsRepository.dart';
import 'package:backend/model/entities/PartnerStatistics.dart';

import 'PartnerStatisticsServiceTest.mocks.dart';

@GenerateMocks([PartnerStatisticsRepository])
void main() {
  late MockPartnerStatisticsRepository repo;
  late PartnerStatisticsService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockPartnerStatisticsRepository();
    sut  = PartnerStatisticsService(repo);
  });

  PartnerStatistics _stats({int id = 1, int partnerId = 1, int pointId = 1}) =>
      PartnerStatistics(
        id: id, partnerId: partnerId, pointId: pointId,
        totalOrders: 0, totalCancel: 0,
        createdAt: DateTime(2024),
      );

  // ── getStatisticsById ─────────────────────────────────────────────────────
  group('getStatisticsById', () {
    test('возвращает статистику', () async {
      when(repo.findById(1)).thenAnswer((_) async => _stats());
      final result = await sut.getStatisticsById(1);
      expect(result.id, 1);
    });

    test('бросает если не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getStatisticsById(99), throwsA(isA<Exception>()));
    });
  });

  // ── createStatistics — валидация ──────────────────────────────────────────
  group('createStatistics — валидация', () {
    test('бросает если partner_id <= 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 0, 'point_id': 1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если point_id <= 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 0}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если total_orders < 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 1, 'total_orders': -1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если total_revenue < 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 1, 'total_revenue': -100.0}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если total_cancel < 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 1, 'total_cancel': -1}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если average_rating > 5', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 1, 'average_rating': 5.5}),
        throwsA(isA<Exception>()),
      );
    });

    test('бросает если average_rating < 0', () {
      expect(
        () => sut.createStatistics({'partner_id': 1, 'point_id': 1, 'average_rating': -0.1}),
        throwsA(isA<Exception>()),
      );
    });

    test('успешно создаёт при корректных данных', () async {
      when(repo.create(any)).thenAnswer((_) async => _stats());
      final result = await sut.createStatistics({'partner_id': 1, 'point_id': 1});
      expect(result.id, 1);
    });
  });

  // ── updateRating ───────────────────────────────────────────────────────────
  group('updateRating', () {
    test('бросает если статистика не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.updateRating(99, 4.0), throwsA(isA<Exception>()));
    });

    test('успешно обновляет рейтинг', () async {
      when(repo.findById(1)).thenAnswer((_) async => _stats());
      when(repo.update(any)).thenAnswer((_) async => _stats());
      await expectLater(sut.updateRating(1, 4.5), completes);
      verify(repo.update(any)).called(1);
    });
  });

  // ── addOrder ───────────────────────────────────────────────────────────────
  group('addOrder', () {
    test('бросает если статистика не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.addOrder(99, 100.0), throwsA(isA<Exception>()));
    });

    test('вызывает update после addOrder', () async {
      when(repo.findById(1)).thenAnswer((_) async => _stats());
      when(repo.update(any)).thenAnswer((_) async => _stats());
      await sut.addOrder(1, 250.0);
      verify(repo.update(any)).called(1);
    });
  });

  // ── addCancel ──────────────────────────────────────────────────────────────
  group('addCancel', () {
    test('бросает если статистика не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.addCancel(99), throwsA(isA<Exception>()));
    });

    test('вызывает update после addCancel', () async {
      when(repo.findById(1)).thenAnswer((_) async => _stats());
      when(repo.update(any)).thenAnswer((_) async => _stats());
      await sut.addCancel(1);
      verify(repo.update(any)).called(1);
    });
  });
}
