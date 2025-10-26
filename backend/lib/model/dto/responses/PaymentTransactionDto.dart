import '../../entities/PaymentTransactions.dart';

class PaymentTransactionDto {
  final int id;
  final int orderId;
  final String paymentMethod;
  final double orderPrice;
  final String status;
  final DateTime transactionDate;
  final DateTime? updatedAt;
  final String? errorMessage;
  final bool isActive;

  PaymentTransactionDto({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.orderPrice,
    required this.status,
    required this.transactionDate,
    this.updatedAt,
    this.errorMessage,
    required this.isActive,
  });

  factory PaymentTransactionDto.fromEntity(PaymentTransactions transaction) {
    return PaymentTransactionDto(
      id: transaction.id,
      orderId: transaction.orderId,
      paymentMethod: transaction.paymentMethod.toString().split('.').last,
      orderPrice: transaction.orderPrice,
      status: transaction.status.toString().split('.').last,
      transactionDate: transaction.transactionDate,
      updatedAt: transaction.updatedAt,
      errorMessage: transaction.errorMessage,
      isActive: transaction.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'payment_method': paymentMethod,
      'order_price': orderPrice,
      'status': status,
      'transaction_date': transactionDate.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (errorMessage != null) 'error_message': errorMessage,
      'is_active': isActive,
    };
  }
}
