import 'package:backend/config/AppConfig.dart';
import 'package:backend/model/entities/Order.dart';
import 'package:backend/model/entities/PaymentTransactions.dart';
import 'package:backend/model/enums/OrderStatus.dart';
import 'package:backend/model/enums/PaymentMethod.dart';
import 'package:backend/model/enums/PaymentTransactionStatus.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/services/PaymentGatewayService.dart';
import 'package:backend/services/YooKassaService.dart';
import 'package:backend/utils/AppException.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'PaymentGatewayServiceTest.mocks.dart';

@GenerateMocks([
  YooKassaService,
  PaymentTransactionsRepository,
  OrderRepository,
  OrderService,
])

void main() {
  late MockYooKassaService yooKassa;
  late MockPaymentTransactionsRepository transactionsRepo;
  late MockOrderRepository orderRepo;
  late MockOrderService orderService;
  late PaymentGatewayService sut;

  setUpAll(() {
    AppConfig.initForTesting();
  });

  setUp(() {
    yooKassa = MockYooKassaService();
    transactionsRepo = MockPaymentTransactionsRepository();
    orderRepo = MockOrderRepository();
    orderService = MockOrderService();
    sut = PaymentGatewayService(
      yooKassaService: yooKassa,
      transactionsRepository: transactionsRepo,
      orderRepository: orderRepo,
      orderService: orderService,
      config: AppConfig(),
    );
  });

  Order _order({
    int id = 10,
    int userId = 7,
    OrderStatus status = OrderStatus.pending,
    DateTime? createdAt,
  }) =>
      Order(
        id: id,
        productsId: const [1, 2],
        userId: userId,
        pointId: 3,
        date: DateTime.now(),
        totalPrice: 1200,
        createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
        status: status,
      );

  PaymentTransactions _tx({
    int id = 1,
    int orderId = 10,
    PaymentTransactionStatus status = PaymentTransactionStatus.completed,
    bool isActive = true,
  }) =>
      PaymentTransactions(
        id: id,
        orderId: orderId,
        providerTransactionId: 'provider-$id',
        confirmationUrl: 'https://pay.example/confirm',
        orderPrice: 1200,
        paymentMethod: PaymentMethod.card,
        status: status,
        transactionDate: DateTime.now(),
        isActive: isActive,
      );

  group('refund', () {
    test('throws ForbiddenException when requesting user is not owner', () async {
      when(orderRepo.findById(10)).thenAnswer((_) async => _order(userId: 99));

      await expectLater(
        () => sut.refund(orderId: 10, requestingUserId: 7),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('throws ConflictException when there are no completed active transactions',
        () async {
      when(orderRepo.findById(10)).thenAnswer((_) async => _order(userId: 7));
      when(transactionsRepo.findByOrderId(10))
          .thenAnswer((_) async => [_tx(status: PaymentTransactionStatus.pending)]);

      await expectLater(
        () => sut.refund(orderId: 10, requestingUserId: 7),
        throwsA(isA<ConflictException>()),
      );
    });

    test('marks transaction refunded and updates order status on success',
        () async {
      final order = _order(userId: 7);
      final completed = _tx(id: 11, orderId: order.id);
      when(orderRepo.findById(order.id)).thenAnswer((_) async => order);
      when(transactionsRepo.findByOrderId(order.id))
          .thenAnswer((_) async => [completed]);
      when(yooKassa.refundPayment(
        providerTransactionId: completed.providerTransactionId,
        amount: completed.orderPrice,
        description: 'Возврат по заказу #${order.id}',
      )).thenAnswer((_) async => <String, dynamic>{'id': 'refund-1'});
      when(transactionsRepo.update(any)).thenAnswer((invocation) async {
        final tx = invocation.positionalArguments.first as PaymentTransactions;
        return tx;
      });
      when(orderService.updateOrderStatus(order.id, OrderStatus.cancelled))
          .thenAnswer((_) async => _order(id: order.id, userId: 7, status: OrderStatus.cancelled));

      final result = await sut.refund(orderId: order.id, requestingUserId: 7);

      expect(result.status, PaymentTransactionStatus.refunded);
      verify(yooKassa.refundPayment(
        providerTransactionId: completed.providerTransactionId,
        amount: completed.orderPrice,
        description: 'Возврат по заказу #${order.id}',
      )).called(1);
      final capturedUpdatedTx =
          verify(transactionsRepo.update(captureAny)).captured.single
              as PaymentTransactions;
      expect(capturedUpdatedTx.status, PaymentTransactionStatus.refunded);
      verify(orderService.updateOrderStatus(order.id, OrderStatus.cancelled))
          .called(1);
    });

    test(
        'throws ConflictException when refund is done but order status update fails',
        () async {
      final order = _order(userId: 7);
      final completed = _tx(id: 12, orderId: order.id);
      when(orderRepo.findById(order.id)).thenAnswer((_) async => order);
      when(transactionsRepo.findByOrderId(order.id))
          .thenAnswer((_) async => [completed]);
      when(yooKassa.refundPayment(
        providerTransactionId: completed.providerTransactionId,
        amount: completed.orderPrice,
        description: 'Возврат по заказу #${order.id}',
      )).thenAnswer((_) async => <String, dynamic>{'id': 'refund-2'});
      when(transactionsRepo.update(any)).thenAnswer((invocation) async {
        final tx = invocation.positionalArguments.first as PaymentTransactions;
        return tx;
      });
      when(orderService.updateOrderStatus(order.id, OrderStatus.cancelled))
          .thenThrow(Exception('db down'));

      await expectLater(
        () => sut.refund(orderId: order.id, requestingUserId: 7),
        throwsA(isA<ConflictException>()),
      );

      final capturedUpdatedTx =
          verify(transactionsRepo.update(captureAny)).captured.single
              as PaymentTransactions;
      expect(capturedUpdatedTx.status, PaymentTransactionStatus.refunded);
      verify(orderService.updateOrderStatus(order.id, OrderStatus.cancelled))
          .called(1);
    });
  });
}
