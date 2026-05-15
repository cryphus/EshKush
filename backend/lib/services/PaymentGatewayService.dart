import '../config/AppConfig.dart';
import '../model/entities/PaymentTransactions.dart';
import '../model/enums/OrderStatus.dart';
import '../model/enums/PaymentMethod.dart';
import '../model/enums/PaymentTransactionStatus.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/PaymentTransactionsRepository.dart';
import '../utils/AppException.dart';
import '../utils/LoggingUtils.dart';
import 'OrderService.dart';
import 'YooKassaService.dart';

class PaymentInitResult {
  final PaymentTransactions transaction;
  final String confirmationUrl;

  PaymentInitResult({
    required this.transaction,
    required this.confirmationUrl,
  });

  Map<String, dynamic> toJson() => {
        'transaction': transaction.toJson(),
        'confirmation_url': confirmationUrl,
      };
}

class PaymentGatewayService {
  final YooKassaService _yooKassa;
  final PaymentTransactionsRepository _transactionsRepository;
  final OrderRepository _orderRepository;
  final OrderService _orderService;
  final AppConfig _config;

  PaymentGatewayService({
    required YooKassaService yooKassaService,
    required PaymentTransactionsRepository transactionsRepository,
    required OrderRepository orderRepository,
    required OrderService orderService,
    required AppConfig config,
  })  : _yooKassa = yooKassaService,
        _transactionsRepository = transactionsRepository,
        _orderRepository = orderRepository,
        _orderService = orderService,
        _config = config;

  Future<PaymentInitResult> initiatePayment({
    required int orderId,
    String? description,
    String? returnUrl,
    PaymentMethod paymentMethod = PaymentMethod.card,
    int? requestingUserId,
  }) async {
    final order = await _orderRepository.findById(orderId);
    if (order == null) {
      throw const NotFoundException('Заказ не найден');
    }
    if (requestingUserId != null && order.userId != requestingUserId) {
      throw const ForbiddenException(
          'Нельзя инициировать оплату чужого заказа');
    }
    if (order.totalPrice <= 0) {
      throw const BadRequestException('Сумма заказа должна быть положительной');
    }

    final providerResponse = await _yooKassa.createPayment(
      amount: order.totalPrice,
      description: description ?? 'Оплата заказа #$orderId',
      orderId: orderId,
      returnUrl: returnUrl,
    );

    final providerId = providerResponse['id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      throw const BadRequestException(
          'YooKassa не вернула идентификатор платежа');
    }

    final confirmationUrl = (providerResponse['confirmation']
            as Map<String, dynamic>?)?['confirmation_url']
        ?.toString();
    if (confirmationUrl == null || confirmationUrl.isEmpty) {
      throw const BadRequestException(
          'YooKassa не вернула ссылку для подтверждения оплаты');
    }

    final status = _mapProviderStatus(providerResponse['status']?.toString());

    final pending = PaymentTransactions(
      id: 0,
      orderId: orderId,
      providerTransactionId: providerId,
      confirmationUrl: confirmationUrl,
      orderPrice: order.totalPrice,
      paymentMethod: paymentMethod,
      status: status,
      transactionDate: DateTime.now(),
    );

    final saved = await _transactionsRepository.create(pending);

    return PaymentInitResult(
      transaction: saved,
      confirmationUrl: confirmationUrl,
    );
  }

  Future<PaymentTransactions?> handleWebhook(
    Map<String, dynamic> payload, {
    String? sharedSecret,
  }) async {
    if (_config.yookassaWebhookSecret.isEmpty) {
      throw const UnauthorizedException(
          'Webhook secret is not configured on server');
    }
    if (sharedSecret == null || sharedSecret.trim().isEmpty) {
      throw const UnauthorizedException('Missing webhook secret');
    }
    if (sharedSecret.trim() != _config.yookassaWebhookSecret) {
      throw const UnauthorizedException('Invalid webhook secret');
    }

    final event = payload['event']?.toString();
    final object = payload['object'];
    if (object is! Map<String, dynamic>) {
      throw const BadRequestException('Webhook payload must contain object');
    }
    final providerId = object['id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      throw const BadRequestException(
          'Webhook payload must contain payment id');
    }

    final transaction =
        await _transactionsRepository.findByProviderTransactionId(providerId);
    if (transaction == null) {
      return null;
    }

    final newStatus = _mapEventToStatus(event, object['status']?.toString());
    String? errorMessage;
    if (newStatus == PaymentTransactionStatus.failed) {
      final cancellationDetails = object['cancellation_details'];
      if (cancellationDetails is Map<String, dynamic>) {
        errorMessage = cancellationDetails['reason']?.toString();
      }
    }

    final updated = transaction.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      errorMessage: errorMessage,
    );
    final saved = await _transactionsRepository.update(updated);

    await _syncOrderStatus(saved);
    return saved;
  }

  Future<PaymentTransactions> refund({
    required int orderId,
    double? amount,
    String? description,
    int? requestingUserId,
  }) async {
    final order = await _orderRepository.findById(orderId);
    if (order == null) {
      throw const NotFoundException('Заказ не найден');
    }
    if (requestingUserId != null && order.userId != requestingUserId) {
      throw const ForbiddenException(
          'Возврат доступен только владельцу заказа');
    }
    if (order.status == OrderStatus.cancelled) {
      throw const ConflictException('Заказ уже отменён');
    }
    if (order.status == OrderStatus.completed) {
      throw const ConflictException(
          'Заказ уже получен — возврат возможен только через поддержку');
    }
    final age = DateTime.now().difference(order.createdAt);
    if (age > _config.refundWindow) {
      throw ConflictException(
        'Срок возврата истёк (${_config.refundWindow.inHours}ч с момента оформления)',
      );
    }

    final transactions = await _transactionsRepository.findByOrderId(orderId);
    final completed = transactions
        .where(
            (t) => t.isActive && t.status == PaymentTransactionStatus.completed)
        .toList();
    if (completed.isEmpty) {
      throw const ConflictException('Нет завершённых транзакций для возврата');
    }
    completed.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final target = completed.first;

    final refundAmount = amount ?? target.orderPrice;
    await _yooKassa.refundPayment(
      providerTransactionId: target.providerTransactionId,
      amount: refundAmount,
      description: description ?? 'Возврат по заказу #$orderId',
    );

    final updated = target.copyWith(
      status: PaymentTransactionStatus.refunded,
      updatedAt: DateTime.now(),
    );
    final saved = await _transactionsRepository.update(updated);

    try {
      await _orderService.updateOrderStatus(orderId, OrderStatus.cancelled);
    } catch (e, st) {
      await LoggingUtils.logError(
        'Refund completed, but failed to update order status (orderId: $orderId)',
        e,
        stackTrace: st,
      );
      throw const ConflictException(
        'Возврат выполнен, но статус заказа не обновлён. Требуется ручная проверка',
      );
    }

    return saved;
  }

  Future<void> _syncOrderStatus(PaymentTransactions transaction) async {
    OrderStatus? target;
    switch (transaction.status) {
      case PaymentTransactionStatus.refunded:
      case PaymentTransactionStatus.failed:
        target = OrderStatus.cancelled;
        break;
      case PaymentTransactionStatus.completed:
      case PaymentTransactionStatus.pending:
        target = null;
        break;
    }
    if (target == null) return;

    try {
      await _orderService.updateOrderStatus(transaction.orderId, target);
    } catch (e, st) {
      await LoggingUtils.logError(
        'Failed to sync order status after webhook (orderId: ${transaction.orderId})',
        e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  PaymentTransactionStatus _mapProviderStatus(String? status) {
    switch (status) {
      case 'succeeded':
        return PaymentTransactionStatus.completed;
      case 'canceled':
        return PaymentTransactionStatus.failed;
      case 'waiting_for_capture':
      case 'pending':
        return PaymentTransactionStatus.pending;
      default:
        return PaymentTransactionStatus.pending;
    }
  }

  PaymentTransactionStatus _mapEventToStatus(String? event, String? status) {
    if (event != null) {
      switch (event) {
        case 'payment.succeeded':
          return PaymentTransactionStatus.completed;
        case 'payment.canceled':
          return PaymentTransactionStatus.failed;
        case 'payment.waiting_for_capture':
          return PaymentTransactionStatus.pending;
        case 'refund.succeeded':
          return PaymentTransactionStatus.refunded;
      }
    }
    return _mapProviderStatus(status);
  }
}
