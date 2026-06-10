import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/OrderHistoryService.dart';
import 'package:backend/repositories/OrderHistoryRepository.dart';
import 'package:backend/model/entities/OrderHistory.dart';
import 'package:backend/model/enums/HistoryStatus.dart';

import 'OrderHistoryServiceTest.mocks.dart';

@GenerateMocks([OrderHistoryRepository])
void main() {
  late MockOrderHistoryRepository repo;
  late OrderHistoryService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockOrderHistoryRepository();
    sut  = OrderHistoryService(repo);
  });

  OrderHistory _history({int id = 1, HistoryStatus status = HistoryStatus.pending}) =>
      OrderHistory(
        id: id, orderId: 1, pointId: 1, userId: 1,
        orderDate: DateTime(2024),
        totalSum: 500.0, status: status,
      );

  // ── getOrderHistoryById ────────────────────────────────────────────────────
  group('getOrderHistoryById', () {
    test('возвращает историю по id', () async {
      when(repo.findById(1)).thenAnswer((_) async => _history());
      final result = await sut.getOrderHistoryById(1);
      expect(result.id, 1);
    });

    test('бросает если не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getOrderHistoryById(99), throwsA(isA<Exception>()));
    });
  });

  // ── getUserOrderHistory ────────────────────────────────────────────────────
  group('getUserOrderHistory', () {
    test('возвращает историю пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_history(id: 1), _history(id: 2)]);
      final result = await sut.getUserOrderHistory(1);
      expect(result.length, 2);
    });
  });

  // ── completeOrder ──────────────────────────────────────────────────────────
  group('completeOrder', () {
    test('обновляет статус на completed', () async {
      final history = _history();
      when(repo.findById(1)).thenAnswer((_) async => history);
      when(repo.update(any)).thenAnswer((_) async => _history(status: HistoryStatus.completed));
      final result = await sut.completeOrder(1, totalSum: 500.0, co2Saved: 10);
      expect(result.status, HistoryStatus.completed);
    });

    test('бросает если история не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(
        () => sut.completeOrder(99, totalSum: 100.0, co2Saved: 5),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── cancelOrder ────────────────────────────────────────────────────────────
  group('cancelOrder', () {
    test('отменяет заказ с указанной причиной', () async {
      final history = _history();
      when(repo.findById(1)).thenAnswer((_) async => history);
      when(repo.update(any)).thenAnswer((_) async => _history(status: HistoryStatus.cancelled));
      final result = await sut.cancelOrder(1, 'Клиент передумал');
      expect(result.status, HistoryStatus.cancelled);
    });

    test('бросает если история не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.cancelOrder(99, 'reason'), throwsA(isA<Exception>()));
    });
  });

  // ── getOrdersByStatus ──────────────────────────────────────────────────────
  group('getOrdersByStatus', () {
    test('возвращает заказы по статусу', () async {
      when(repo.getByStatus(HistoryStatus.pending))
          .thenAnswer((_) async => [_history(status: HistoryStatus.pending)]);
      final result = await sut.getOrdersByStatus(HistoryStatus.pending);
      expect(result.length, 1);
    });
  });

  // ── getOrdersByDateRange ───────────────────────────────────────────────────
  group('getOrdersByDateRange', () {
    test('возвращает заказы за период', () async {
      final start = DateTime(2024, 1);
      final end   = DateTime(2024, 12);
      when(repo.getByDateRange(start, end)).thenAnswer((_) async => [_history()]);
      final result = await sut.getOrdersByDateRange(start, end);
      expect(result.length, 1);
    });
  });
}
