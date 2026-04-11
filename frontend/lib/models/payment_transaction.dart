enum PaymentTransactionStatus { pending, completed, failed, refunded }

PaymentTransactionStatus paymentStatusFromString(String value) {
  return PaymentTransactionStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => PaymentTransactionStatus.pending,
  );
}

enum PaymentMethod { cash, card, creditCard, mobilePayment, other }

PaymentMethod paymentMethodFromString(String value) {
  return PaymentMethod.values.firstWhere(
    (e) => e.name == value,
    orElse: () => PaymentMethod.other,
  );
}

class PaymentTransaction {
  final int id;
  final int orderId;
  final String providerTransactionId;
  final String? confirmationUrl;
  final double orderPrice;
  final PaymentMethod paymentMethod;
  final PaymentTransactionStatus status;
  final DateTime transactionDate;
  final DateTime? updatedAt;
  final String? errorMessage;
  final bool isActive;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.providerTransactionId,
    this.confirmationUrl,
    required this.orderPrice,
    required this.paymentMethod,
    required this.status,
    required this.transactionDate,
    this.updatedAt,
    this.errorMessage,
    this.isActive = true,
  });

  bool get isPending => status == PaymentTransactionStatus.pending;
  bool get isCompleted => status == PaymentTransactionStatus.completed;
  bool get isFailed => status == PaymentTransactionStatus.failed;
  bool get isRefunded => status == PaymentTransactionStatus.refunded;

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      providerTransactionId: json['provider_transaction_id']?.toString() ?? '',
      confirmationUrl: json['confirmation_url'] as String?,
      orderPrice: (json['order_price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: paymentMethodFromString(
          json['payment_method'] as String? ?? 'other'),
      status: paymentStatusFromString(json['status'] as String? ?? 'pending'),
      transactionDate: DateTime.parse(json['transaction_date']
          ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Ответ backend `POST /payments/create`.
class PaymentInitResponse {
  final PaymentTransaction transaction;
  final String confirmationUrl;

  const PaymentInitResponse({
    required this.transaction,
    required this.confirmationUrl,
  });

  factory PaymentInitResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitResponse(
      transaction: PaymentTransaction.fromJson(
          json['transaction'] as Map<String, dynamic>),
      confirmationUrl: json['confirmation_url'] as String,
    );
  }
}
