import '../model/entities/PaymentTransactions.dart';
import '../repositories/PaymentTransactionsRepository.dart';
import '../model/enums/PaymentMethod.dart';
import '../model/enums/PaymentTransactionStatus.dart';

class PaymentTransactionsService {
  final PaymentTransactionsRepository _repository;

  PaymentTransactionsService(this._repository);

  Future<PaymentTransactions> getTransactionById(int id) async {
    final transaction = await _repository.findById(id);
    if (transaction == null) {
      throw Exception('Транзакция не найдена');
    }
    return transaction;
  }

  Future<List<PaymentTransactions>> getTransactionsByUserId(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<List<PaymentTransactions>> getTransactionsByOrderId(int orderId) async {
    return await _repository.findByOrderId(orderId);
  }

  Future<PaymentTransactions> createTransaction(Map<String, dynamic> data) async {
    _validateTransactionData(data);
    final now = DateTime.now();
    final transaction = PaymentTransactions(
      id: 0, // будет установлен базой
      orderId: data['order_id'] as int,
      providerTransactionId: data['provider_transaction_id'] as int,
      orderPrice: (data['order_price'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['payment_method']}',
        orElse: () => PaymentMethod.other,
      ),
      status: PaymentTransactionStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentTransactionStatus.${data['status']}',
        orElse: () => PaymentTransactionStatus.completed,
      ),
      transactionDate: DateTime.parse(data['transaction_date'] as String),
      updatedAt: now,
      errorMessage: data['error_message'] as String?,
      isActive: data['is_active'] ?? true,
    );
    return await _repository.create(transaction);
  }

  Future<PaymentTransactions> updateTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    _validateTransactionData(data);
    final existingTransaction = await getTransactionById(id);
    final updatedTransaction = existingTransaction.copyWith(
      orderId: data['order_id'] as int?,
      providerTransactionId: data['provider_transaction_id'] as int?,
      orderPrice: data['order_price'] != null ? (data['order_price'] as num).toDouble() : null,
      paymentMethod: data['payment_method'] != null
        ? PaymentMethod.values.firstWhere(
            (e) => e.toString() == 'PaymentMethod.${data['payment_method']}',
            orElse: () => PaymentMethod.other,
          )
        : null,
      status: data['status'] != null
        ? PaymentTransactionStatus.values.firstWhere(
            (e) => e.toString() == 'PaymentTransactionStatus.${data['status']}',
            orElse: () => PaymentTransactionStatus.completed,
          )
        : null,
      transactionDate: data['transaction_date'] != null
        ? DateTime.parse(data['transaction_date'] as String)
        : null,
      updatedAt: DateTime.now(),
      errorMessage: data['error_message'] as String?,
      isActive: data['is_active'] as bool?,
    );
    return await _repository.update(updatedTransaction);
  }

  Future<void> deactivateTransaction(int id) async {
    await _repository.deactivate(id);
  }

  Future<void> activateTransaction(int id) async {
    await _repository.activate(id);
  }

  Future<List<PaymentTransactions>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _repository.findByDateRange(startDate, endDate);
  }

  Future<List<PaymentTransactions>> getTransactionsByStatus(String status) async {
    return await _repository.findByStatus(status);
  }

  Future<List<PaymentTransactions>> getTransactionsByPaymentMethod(
    String paymentMethod,
  ) async {
    return await _repository.findByPaymentMethod(paymentMethod);
  }

  void _validateTransactionData(Map<String, dynamic> data) {
    if (data['order_id'] == null) {
      throw Exception('ID заказа обязателен');
    }
    if (data['provider_transaction_id'] == null) {
      throw Exception('ID транзакции провайдера обязателен');
    }
    if (data['order_price'] == null) {
      throw Exception('Сумма обязательна');
    }
    if (data['payment_method'] == null) {
      throw Exception('Метод оплаты обязателен');
    }
    if (data['status'] == null) {
      throw Exception('Статус обязателен');
    }
    if (data['transaction_date'] == null) {
      throw Exception('Дата транзакции обязательна');
    }
  }
} 