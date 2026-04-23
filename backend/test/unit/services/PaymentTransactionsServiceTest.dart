import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/PaymentTransactionsService.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:backend/model/entities/PaymentTransactions.dart';
import 'package:backend/model/enums/PaymentMethod.dart';
import 'package:backend/model/enums/PaymentTransactionStatus.dart';

import 'PaymentTransactionsServiceTest.mocks.dart';

@GenerateMocks([PaymentTransactionsRepository])
void main() {
  late MockPaymentTransactionsRepository repo;
  late PaymentTransactionsService sut;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    repo = MockPaymentTransactionsRepository();
    sut  = PaymentTransactionsService(repo);
  });

  PaymentTransactions _tx() => PaymentTransactions(
    id: 1, orderId: 1, providerTransactionId: '100',
    orderPrice: 500.0, paymentMethod: PaymentMethod.card,
    status: PaymentTransactionStatus.completed,
    transactionDate: DateTime(2024),
    updatedAt: DateTime(2024),
    isActive: true,
  );

  Map<String, dynamic> _validData() => {
    'order_id': 1,
    'provider_transaction_id': '100',
    'order_price': 500.0,
    'payment_method': 'card',
    'status': 'completed',
    'transaction_date': '2024-01-01T00:00:00.000',
  };

  // ── getTransactionById ─────────────────────────────────────────────────────
  group('getTransactionById', () {
    test('возвращает транзакцию', () async {
      when(repo.findById(1)).thenAnswer((_) async => _tx());
      final result = await sut.getTransactionById(1);
      expect(result.id, 1);
    });

    test('бросает если не найдена', () async {
      when(repo.findById(99)).thenAnswer((_) async => null);
      expect(() => sut.getTransactionById(99), throwsA(isA<Exception>()));
    });
  });

  // ── createTransaction — валидация ─────────────────────────────────────────
  group('createTransaction — валидация', () {
    test('бросает если отсутствует order_id', () {
      final data = _validData()..remove('order_id');
      expect(() => sut.createTransaction(data), throwsA(isA<Exception>()));
    });

    test('бросает если отсутствует provider_transaction_id', () {
      final data = _validData()..remove('provider_transaction_id');
      expect(() => sut.createTransaction(data), throwsA(isA<Exception>()));
    });

    test('бросает если отсутствует order_price', () {
      final data = _validData()..remove('order_price');
      expect(() => sut.createTransaction(data), throwsA(isA<Exception>()));
    });

    test('бросает если отсутствует payment_method', () {
      final data = _validData()..remove('payment_method');
      expect(() => sut.createTransaction(data), throwsA(isA<Exception>()));
    });

    test('бросает если отсутствует status', () {
      final data = _validData()..remove('status');
      expect(() => sut.createTransaction(data), throwsA(isA<Exception>()));
    });

    test('принимает без transaction_date — использует текущую дату', () async {
      final data = _validData()..remove('transaction_date');
      when(repo.create(any)).thenAnswer((_) async => _tx());
      final result = await sut.createTransaction(data);
      expect(result.id, 1);
    });

    test('createTransaction с id=0 успешно делегирует в репозиторий', () async {
      when(repo.create(any)).thenAnswer((_) async => _tx());
      final result = await sut.createTransaction(_validData());
      expect(result.id, 1);
    });
  });

  // ── getTransactionsByUserId ────────────────────────────────────────────────
  group('getTransactionsByUserId', () {
    test('возвращает транзакции пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_tx()]);
      final result = await sut.getTransactionsByUserId(1);
      expect(result.length, 1);
    });
  });
}
