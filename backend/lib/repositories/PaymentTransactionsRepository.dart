import 'package:postgres/postgres.dart';
import '../model/entities/PaymentTransactions.dart';
import 'BaseRepository.dart';
import '../utils/AppException.dart';

class PaymentTransactionsRepository extends BaseRepository {
  PaymentTransactionsRepository(PostgreSQLConnection connection)
      : super(connection);

  Future<PaymentTransactions?> findById(int id) async {
    final results = await connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE id = @id',
      substitutionValues: {'id': id},
    );
    if (results.isEmpty) return null;
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<List<PaymentTransactions>> findByUserId(int userId) async {
    final results = await connection.mappedResultsQuery(
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

  /// Принадлежит ли заказ пользователю (для доступа к транзакциям заказа).
  Future<bool> isOrderOwnedByUser({
    required int orderId,
    required int userId,
  }) async {
    final results = await connection.mappedResultsQuery(
      '''
      SELECT 1 AS owns
      FROM orders o
      WHERE o.id = @orderId AND o.user_id = @userId
      LIMIT 1
      ''',
      substitutionValues: {
        'orderId': orderId,
        'userId': userId,
      },
    );
    return results.isNotEmpty;
  }

  Future<bool> isOwnedByUser({
    required int transactionId,
    required int userId,
  }) async {
    final results = await connection.mappedResultsQuery(
      '''
      SELECT 1 AS owns
      FROM payment_transactions pt
      JOIN orders o ON pt.order_id = o.id
      WHERE pt.id = @transactionId AND o.user_id = @userId
      LIMIT 1
      ''',
      substitutionValues: {
        'transactionId': transactionId,
        'userId': userId,
      },
    );
    return results.isNotEmpty;
  }

  Future<List<PaymentTransactions>> findByOrderId(int orderId) async {
    final results = await connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE order_id = @orderId',
      substitutionValues: {'orderId': orderId},
    );
    return results
        .map((row) => PaymentTransactions.fromJson(row.values.first))
        .toList();
  }

  Future<PaymentTransactions> create(PaymentTransactions transaction) async {
    final results = await connection.mappedResultsQuery(
      '''
      INSERT INTO payment_transactions (
        order_id, provider_transaction_id, confirmation_url, order_price, payment_method, status, transaction_date, updated_at, error_message, is_active
      ) VALUES (
        @orderId, @providerTransactionId, @confirmationUrl, @orderPrice, @paymentMethod, @status, @transactionDate, @updatedAt, @errorMessage, @isActive
      ) RETURNING *
      ''',
      substitutionValues: {
        'orderId': transaction.orderId,
        'providerTransactionId': transaction.providerTransactionId,
        'confirmationUrl': transaction.confirmationUrl,
        'orderPrice': transaction.orderPrice,
        'paymentMethod': transaction.paymentMethod.toString().split('.').last,
        'status': transaction.status.toString().split('.').last,
        'transactionDate':
            transaction.transactionDate.toUtc().toIso8601String(),
        'updatedAt': transaction.updatedAt?.toIso8601String(),
        'errorMessage': transaction.errorMessage,
        'isActive': transaction.isActive,
      },
    );
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<PaymentTransactions> update(PaymentTransactions transaction) async {
    final results = await connection.mappedResultsQuery(
      '''
      UPDATE payment_transactions SET
        order_id = @orderId,
        provider_transaction_id = @providerTransactionId,
        confirmation_url = @confirmationUrl,
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
        'confirmationUrl': transaction.confirmationUrl,
        'orderPrice': transaction.orderPrice,
        'paymentMethod': transaction.paymentMethod.toString().split('.').last,
        'status': transaction.status.toString().split('.').last,
        'transactionDate':
            transaction.transactionDate.toUtc().toIso8601String(),
        'updatedAt': transaction.updatedAt?.toIso8601String(),
        'errorMessage': transaction.errorMessage,
        'isActive': transaction.isActive,
      },
    );
    if (results.isEmpty) {
      throw const NotFoundException();
    }
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<PaymentTransactions?> findByProviderTransactionId(
      String providerTransactionId) async {
    final results = await connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE provider_transaction_id = @providerTransactionId LIMIT 1',
      substitutionValues: {'providerTransactionId': providerTransactionId},
    );
    if (results.isEmpty) return null;
    return PaymentTransactions.fromJson(results.first.values.first);
  }

  Future<void> deactivate(int id) async {
    await connection.execute(
      'UPDATE payment_transactions SET is_active = false WHERE id = @id',
      substitutionValues: {'id': id},
    );
  }

  Future<void> activate(int id) async {
    await connection.execute(
      'UPDATE payment_transactions SET is_active = true WHERE id = @id',
      substitutionValues: {'id': id},
    );
  }

  Future<List<PaymentTransactions>> findByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await connection.mappedResultsQuery(
      '''
      SELECT * FROM payment_transactions 
      WHERE transaction_date BETWEEN @startDate AND @endDate
      ''',
      substitutionValues: {
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      },
    );
    return results
        .map((row) => PaymentTransactions.fromJson(row.values.first))
        .toList();
  }

  Future<List<PaymentTransactions>> findByStatus(String status) async {
    final results = await connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE status = @status',
      substitutionValues: {'status': status},
    );
    return results
        .map((row) => PaymentTransactions.fromJson(row.values.first))
        .toList();
  }

  Future<List<PaymentTransactions>> findByPaymentMethod(
      String paymentMethod) async {
    final results = await connection.mappedResultsQuery(
      'SELECT * FROM payment_transactions WHERE payment_method = @paymentMethod',
      substitutionValues: {'paymentMethod': paymentMethod},
    );
    return results
        .map((row) => PaymentTransactions.fromJson(row.values.first))
        .toList();
  }
}
