import '../config/AppConfig.dart';
import '../model/entities/PaymentTransactions.dart';
import '../model/enums/OrderStatus.dart';
import '../model/enums/PaymentMethod.dart';
import '../model/enums/PaymentTransactionStatus.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/PaymentTransactionsRepository.dart';
import '../utils/LoggingUtils.dart';
import 'OrderService.dart';
import 'YooKassaService.dart';

/// Доменная ошибка при попытке возврата — валидационная,
/// контроллер конвертирует её в 409/400.
class RefundException implements Exception {
  final String message;
  RefundException(this.message);

  @override
  String toString() => message;
}

/// Результат инициации платежа, возвращается фронту для редиректа.
class PaymentInitResult {
  final PaymentTransactions transaction;
  final String confirmationUrl;

  PaymentInitResult({required this.transaction, required this.confirmationUrl});

  Map<String, dynamic> toJson() => {
        'transaction': transaction.toJson(),
        'confirmation_url': confirmationUrl,
      };
}

/// Связывает YooKassa и наш слой транзакций.
///
/// Фронт дергает [initiatePayment], получает confirmation_url и редиректит
/// пользователя. YooKassa после оплаты шлёт webhook, который обрабатывается
/// через [handleWebhook] — тот обновляет статус PaymentTransactions и
/// соответствующего заказа.
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
  }) async {
    final order = await _orderRepository.findById(orderId);
    if (order == null) {
      throw Exception('Заказ не найден');
    }
    if (order.totalPrice <= 0) {
      throw Exception('Сумма заказа должна быть положительной');
    }

    final providerResponse = await _yooKassa.createPayment(
      amount: order.totalPrice,
      description: description ?? 'Оплата заказа #$orderId',
      orderId: orderId,
      returnUrl: returnUrl,
    );

    final providerId = providerResponse['id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      throw Exception('YooKassa не вернула идентификатор платежа');
    }

    final confirmationUrl = (providerResponse['confirmation']
            as Map<String, dynamic>?)?['confirmation_url']
        ?.toString();
    if (confirmationUrl == null || confirmationUrl.isEmpty) {
      throw Exception('YooKassa не вернула ссылку для подтверждения оплаты');
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

  /// Обработка входящего webhook от YooKassa.
  /// Схема: { event: 'payment.succeeded'|'payment.canceled'|..., object: { id, status, ... } }
  Future<PaymentTransactions?> handleWebhook(
    Map<String, dynamic> payload, {
    String? sharedSecret,
  }) async {
    if (_config.yookassaWebhookSecret.isEmpty) {
      if (_config.isProduction) {
        throw Exception('Webhook секрет не настроен — запрос отклонён');
      }
    } else if (sharedSecret != _config.yookassaWebhookSecret) {
      throw Exception('Неверный секрет webhook');
    }

    final event = payload['event']?.toString();
    final object = payload['object'];
    if (object is! Map<String, dynamic>) {
      throw Exception('Webhook не содержит object');
    }
    final providerId = object['id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      throw Exception('Webhook не содержит идентификатора платежа');
    }

    final transaction =
        await _transactionsRepository.findByProviderTransactionId(providerId);
    if (transaction == null) {
      // Платёж мог прийти для неизвестной транзакции — просто сигналим.
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
      throw RefundException('Заказ не найден');
    }
    if (requestingUserId != null && order.userId != requestingUserId) {
      throw RefundException('Возврат доступен только владельцу заказа');
    }
    if (order.status == OrderStatus.cancelled) {
      throw RefundException('Заказ уже отменён');
    }
    if (order.status == OrderStatus.completed) {
      throw RefundException(
          'Заказ уже получен — возврат возможен только через поддержку');
    }
    final age = DateTime.now().difference(order.createdAt);
    if (age > _config.refundWindow) {
      throw RefundException(
        'Срок возврата истёк '
        '(${_config.refundWindow.inHours}ч с момента оформления)',
      );
    }

    final transactions =
        await _transactionsRepository.findByOrderId(orderId);
    final completed = transactions
        .where((t) =>
            t.isActive && t.status == PaymentTransactionStatus.completed)
        .toList();
    if (completed.isEmpty) {
      throw RefundException('Нет завершённых транзакций для возврата');
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
    } catch (e) {
      // Не блокируем возврат, если не удалось обновить статус заказа.
      await LoggingUtils.logError('Не удалось обновить статус заказа после возврата', e, context: {'orderId': orderId});
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
        // Оплата прошла, но у заказа нет отдельного статуса "paid" —
        // оставляем pending, пока партнёр не подтвердит выдачу.
        target = null;
        break;
    }
    if (target == null) return;
    try {
      await _orderService.updateOrderStatus(transaction.orderId, target);
    } catch (e) {
      await LoggingUtils.logError('Не удалось синхронизировать статус заказа после webhook', e, context: {'orderId': transaction.orderId});
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
