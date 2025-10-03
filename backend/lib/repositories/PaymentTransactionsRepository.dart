import 'package:postgres/postgres.dart';
import '../model/entities/PaymentTransactions.dart';

class PaymentTransactionsRepository {
  final PostgreSQLConnection _connection;

  PaymentTransactionsRepository(this._connection);

  Future<PaymentTransactions?> findById(int id) async {
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE id = @id',
      substitutionValues: {'id': id},
    );
    if (results.isEmpty) return null;
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<List<PaymentTransactions>> findByUserId(int userId) async {
    final results = await _connection.mappedResultsQuery(
      '''
      SELECT pt.* FROM payment_transactions pt
      JOIN orders o ON pt.order_id = o.id
      WHERE o.user_id = @userId
      ''',
      substitutionValues: {'userId': userId},
    );

    return results
        .map((row) => PaymentTransactions.fromJson(row.values.first))
        .toList();
  }

  Future<List<PaymentTransactions>> findByOrderId(int orderId) async {
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE order_id = @orderId',
      substitutionValues: {'orderId': orderId},
    );
    return results.map((row) => PaymentTransactions.fromJson(row.values.first)).toList();
  }

  Future<PaymentTransactions> create(PaymentTransactions transaction) async {
    final results = await _connection.mappedResultsQuery(
      '''
      INSERT INTO payment_transactions (
        order_id, provider_transaction_id, order_price, payment_method, status, transaction_date, updated_at, error_message, is_active
      ) VALUES (
        @orderId, @providerTransactionId, @orderPrice, @paymentMethod, @status, @transactionDate, @updatedAt, @errorMessage, @isActive
      ) RETURNING *
      ''',
      substitutionValues: {
        'orderId': transaction.orderId,
        'providerTransactionId': transaction.providerTransactionId,
        'orderPrice': transaction.orderPrice,
        'paymentMethod': transaction.paymentMethod.toString().split('.').last,
        'status': transaction.status.toString().split('.').last,
        'transactionDate': transaction.transactionDate.toIso8601String(),
        'updatedAt': transaction.updatedAt?.toIso8601String(),
        'errorMessage': transaction.errorMessage,
        'isActive': transaction.isActive,
      },
    );
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<PaymentTransactions> update(PaymentTransactions transaction) async {
    final results = await _connection.mappedResultsQuery(
      '''
      UPDATE payment_transactions SET
        order_id = @orderId,
        provider_transaction_id = @providerTransactionId,
        order_price = @orderPrice,
        payment_method = @paymentMethod,
        status = @status,
        transaction_date = @transactionDate,
        updated_at = @updatedAt,
        error_message = @errorMessage,
        is_active = @isActive
      WHERE id = @id
      RETURNING *
      ''',
      substitutionValues: {
        'id': transaction.id,
        'orderId': transaction.orderId,
        'providerTransactionId': transaction.providerTransactionId,
        'orderPrice': transaction.orderPrice,
        'paymentMethod': transaction.paymentMethod.toString().split('.').last,
        'status': transaction.status.toString().split('.').last,
        'transactionDate': transaction.transactionDate.toIso8601String(),
        'updatedAt': transaction.updatedAt?.toIso8601String(),
        'errorMessage': transaction.errorMessage,
        'isActive': transaction.isActive,
      },
    );
    if (results.isEmpty) {
      throw Exception('Транзакция не найдена');
    }
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<void> deactivate(int id) async {
    await _connection.execute(
      'UPDATE payment_transactions SET is_active = false WHERE id = @id',
      substitutionValues: {'id': id},
    );
  }

  Future<void> activate(int id) async {
    await _connection.execute(
      'UPDATE payment_transactions SET is_active = true WHERE id = @id',
      substitutionValues: {'id': id},
    );
  }

  Future<List<PaymentTransactions>> findByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _connection.mappedResultsQuery(
      '''
      SELECT * FROM payment_transactions 
      WHERE transaction_date BETWEEN @startDate AND @endDate
      ''',
      substitutionValues: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return results.map((row) => PaymentTransactions.fromJson(row.values.first)).toList();
  }

  Future<List<PaymentTransactions>> findByStatus(String status) async {
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE status = @status',
      substitutionValues: {'status': status},
    );
    return results.map((row) => PaymentTransactions.fromJson(row.values.first)).toList();
  }

  Future<List<PaymentTransactions>> findByPaymentMethod(String paymentMethod) async {
    final results = await _connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE payment_method = @paymentMethod',
      substitutionValues: {'paymentMethod': paymentMethod},
    );
    return results.map((row) => PaymentTransactions.fromJson(row.values.first)).toList();
  }
} 