import '../model/entities/PaymentTransactions.dart';
import '../model/enums/PaymentMethod.dart';
import '../model/enums/PaymentTransactionStatus.dart';
import '../repositories/PaymentTransactionsRepository.dart';
import '../utils/AppException.dart';

class PaymentTransactionsService {
  final PaymentTransactionsRepository _repository;

  PaymentTransactionsService(this._repository);

  Future<PaymentTransactions> getTransactionById(int id) async {
    final transaction = await _repository.findById(id);
    if (transaction == null) {
      throw const NotFoundException('Транзакция не найдена');
    }
    return transaction;
  }

  Future<List<PaymentTransactions>> getTransactionsByUserId(int userId) async {
    return _repository.findByUserId(userId);
  }

  Future<List<PaymentTransactions>> getTransactionsByOrderId(
      int orderId) async {
    return _repository.findByOrderId(orderId);
  }

  Future<PaymentTransactions> createTransaction(
      Map<String, dynamic> data) async {
    _validateTransactionData(data);
    final now = DateTime.now();
    final transaction = PaymentTransactions(
      id: 0,
      orderId: data['order_id'] as int,
      providerTransactionId: data['provider_transaction_id'].toString(),
      confirmationUrl: data['confirmation_url'] as String?,
      orderPrice: double.parse(data['order_price'].toString()),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == data['payment_method'],
        orElse: () => PaymentMethod.other,
      ),
      status: PaymentTransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => PaymentTransactionStatus.pending,
      ),
      transactionDate: data['transaction_date'] != null
          ? DateTime.parse(data['transaction_date'] as String)
          : now,
      updatedAt: now,
      errorMessage: data['error_message'] as String?,
      isActive: data['is_active'] ?? true,
    );
    return _repository.create(transaction);
  }

  Future<PaymentTransactions> updateTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    final existingTransaction = await getTransactionById(id);
    final updatedTransaction = existingTransaction.copyWith(
      orderId: data['order_id'] as int?,
      providerTransactionId: data['provider_transaction_id']?.toString(),
      confirmationUrl: data['confirmation_url'] as String?,
      orderPrice: data['order_price'] != null
          ? double.parse(data['order_price'].toString())
          : null,
      paymentMethod: data['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == data['payment_method'],
              orElse: () => PaymentMethod.other,
            )
          : null,
      status: data['status'] != null
          ? PaymentTransactionStatus.values.firstWhere(
              (e) => e.toString().split('.').last == data['status'],
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
    return _repository.update(updatedTransaction);
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
    return _repository.findByDateRange(startDate, endDate);
  }

  Future<List<PaymentTransactions>> getTransactionsByStatus(
      String status) async {
    return _repository.findByStatus(status);
  }

  Future<List<PaymentTransactions>> getTransactionsByPaymentMethod(
    String paymentMethod,
  ) async {
    return _repository.findByPaymentMethod(paymentMethod);
  }

  void _validateTransactionData(Map<String, dynamic> data) {
    if (data['order_id'] == null) {
      throw const BadRequestException('ID заказа обязателен');
    }
    if (data['provider_transaction_id'] == null) {
      throw const BadRequestException('ID транзакции провайдера обязателен');
    }
    if (data['order_price'] == null) {
      throw const BadRequestException('Сумма обязательна');
    }
    if (data['payment_method'] == null) {
      throw const BadRequestException('Метод оплаты обязателен');
    }
    if (data['status'] == null) {
      throw const BadRequestException('Статус обязателен');
    }
  }
}
