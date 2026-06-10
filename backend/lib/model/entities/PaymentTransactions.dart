import 'package:backend/model/enums/PaymentMethod.dart';
import 'package:backend/model/enums/PaymentTransactionStatus.dart';

class PaymentTransactions {
  final int id;
  final int orderId;
  PaymentMethod paymentMethod;
  double orderPrice;
  PaymentTransactionStatus status;
  final String providerTransactionId;
  String? confirmationUrl;
  DateTime transactionDate;
  final DateTime? updatedAt;
  String? errorMessage;
  bool isActive;

  PaymentTransactions({
    required this.id,
    required this.orderId,
    required this.providerTransactionId,
    this.orderPrice = 0.0,
    required this.transactionDate,
    this.paymentMethod = PaymentMethod.other,
    this.status = PaymentTransactionStatus.pending,
    this.confirmationUrl,
    this.updatedAt,
    this.errorMessage,
    this.isActive = true,
  }) {
    _validate();
  }

  void _validate() {
    if (id < 0) {
      throw ArgumentError('ID транзакции должен быть неотрицательным');
    }
    if (orderId <= 0) {
      throw ArgumentError('ID заказа должен быть положительным числом');
    }
    if (providerTransactionId.isEmpty) {
      throw ArgumentError('ID транзакции провайдера не может быть пустым');
    }
    if (orderPrice < 0) {
      throw ArgumentError('Стоимость заказа не может быть отрицательной');
    }
  }

  void updateStatus(PaymentTransactionStatus newStatus, {String? error}) {
    status = newStatus;
    if (error != null) {
      errorMessage = error;
    }
  }

  void updatePaymentMethod(PaymentMethod newMethod) {
    paymentMethod = newMethod;
  }

  void updateOrderPrice(double newPrice) {
    if (newPrice < 0) {
      throw ArgumentError('Стоимость заказа не может быть отрицательной');
    }
    orderPrice = newPrice;
  }

  void deactivate() {
    isActive = false;
  }

  void activate() {
    isActive = true;
  }

  factory PaymentTransactions.fromJson(Map<String, dynamic> json) {
    return PaymentTransactions(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      providerTransactionId: json['provider_transaction_id'].toString(),
      confirmationUrl: json['confirmation_url'] as String?,
      orderPrice: json['order_price'] is String
          ? double.parse(json['order_price'] as String)
          : (json['order_price'] as num).toDouble(),
      transactionDate: json['transaction_date'] is DateTime
          ? json['transaction_date'] as DateTime
          : DateTime.parse(json['transaction_date'] as String),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['payment_method']}',
        orElse: () => PaymentMethod.other,
      ),
      status: PaymentTransactionStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentTransactionStatus.${json['status']}',
        orElse: () => PaymentTransactionStatus.pending,
      ),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is DateTime
              ? json['updated_at'] as DateTime
              : DateTime.parse(json['updated_at'] as String))
          : null,
      errorMessage: json['error_message'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'provider_transaction_id': providerTransactionId,
      'confirmation_url': confirmationUrl,
      'order_price': orderPrice,
      'transaction_date': transactionDate.toIso8601String(),
      'payment_method': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'updated_at': updatedAt?.toIso8601String(),
      'error_message': errorMessage,
      'is_active': isActive,
    };
  }

  PaymentTransactions copyWith({
    int? id,
    int? orderId,
    PaymentMethod? paymentMethod,
    double? orderPrice,
    PaymentTransactionStatus? status,
    String? providerTransactionId,
    String? confirmationUrl,
    DateTime? transactionDate,
    DateTime? updatedAt,
    String? errorMessage,
    bool? isActive,
  }) {
    return PaymentTransactions(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderPrice: orderPrice ?? this.orderPrice,
      status: status ?? this.status,
      providerTransactionId: providerTransactionId ?? this.providerTransactionId,
      confirmationUrl: confirmationUrl ?? this.confirmationUrl,
      transactionDate: transactionDate ?? this.transactionDate,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTransactions &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          paymentMethod == other.paymentMethod &&
          orderPrice == other.orderPrice &&
          status == other.status &&
          providerTransactionId == other.providerTransactionId &&
          confirmationUrl == other.confirmationUrl &&
          transactionDate == other.transactionDate &&
          updatedAt == other.updatedAt &&
          errorMessage == other.errorMessage &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      paymentMethod.hashCode ^
      orderPrice.hashCode ^
      status.hashCode ^
      providerTransactionId.hashCode ^
      confirmationUrl.hashCode ^
      transactionDate.hashCode ^
      updatedAt.hashCode ^
      errorMessage.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'PaymentTransactions(id: $id, orderId: $orderId, paymentMethod: $paymentMethod, '
      'orderPrice: $orderPrice, status: $status, providerTransactionId: $providerTransactionId, '
      'transactionDate: $transactionDate, isActive: $isActive)';
}
