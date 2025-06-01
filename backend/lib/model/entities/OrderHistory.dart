import 'package:backend/model/enums/HistoryStatus.dart';

class OrderHistory {
  final int id;
  final int orderId;
  final int pointId;
  final int userId;
  DateTime orderDate;
  DateTime? completionDate;
  double totalSum;
  HistoryStatus status;
  String? receiptLink;
  double? discountApplied;
  String? promoCodeUsed;
  int? co2Saved;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  OrderHistory({
    required this.id,
    required this.orderId,
    required this.pointId,
    required this.userId,
    required this.orderDate,
    this.completionDate,
    this.totalSum = 0,
    this.status = HistoryStatus.pending,
    this.receiptLink,
    this.discountApplied,
    this.promoCodeUsed,
    this.co2Saved,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now() {
    if (totalSum < 0) throw ArgumentError('Total sum cannot be negative');
    if (co2Saved != null && co2Saved! < 0) throw ArgumentError('CO2 saved cannot be negative');
    if (discountApplied != null && discountApplied! < 0) {
      throw ArgumentError('Discount cannot be negative');
    }
  }

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      pointId: json['pointId'] as int,
      userId: json['userId'] as int,
      orderDate: DateTime.parse(json['orderDate'] as String),
      completionDate: json['completionDate'] != null 
          ? DateTime.parse(json['completionDate'] as String) 
          : null,
      totalSum: (json['totalSum'] as num).toDouble(),
      status: HistoryStatus.values.firstWhere(
        (e) => e.toString() == 'HistoryStatus.${json['status']}',
        orElse: () => HistoryStatus.pending,
      ),
      receiptLink: json['receiptLink'] as String?,
      discountApplied: json['discountApplied'] != null 
          ? (json['discountApplied'] as num).toDouble() 
          : null,
      promoCodeUsed: json['promoCodeUsed'] as String?,
      co2Saved: json['co2Saved'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'pointId': pointId,
      'userId': userId,
      'orderDate': orderDate.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'totalSum': totalSum,
      'status': status.toString().split('.').last,
      'receiptLink': receiptLink,
      'discountApplied': discountApplied,
      'promoCodeUsed': promoCodeUsed,
      'co2Saved': co2Saved,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  void completeOrder({
    required double totalSum,
    required int co2Saved,
    String? receiptLink,
    double? discountApplied,
    String? promoCodeUsed,
    String? notes,
  }) {
    if (status == HistoryStatus.completed) {
      throw StateError('Order is already completed');
    }

    this.totalSum = totalSum;
    this.co2Saved = co2Saved;
    this.receiptLink = receiptLink;
    this.discountApplied = discountApplied;
    this.promoCodeUsed = promoCodeUsed;
    this.notes = notes;
    completionDate = DateTime.now();
    status = HistoryStatus.completed;
    updatedAt = DateTime.now();
  }

  void cancelOrder(String reason) {
    if (status == HistoryStatus.completed) {
      throw StateError('Cannot cancel completed order');
    }

    status = HistoryStatus.cancelled;
    notes = '${notes ?? ''}\nCancelled: $reason';
    updatedAt = DateTime.now();
  }

  bool get isCompleted => status == HistoryStatus.completed;
  bool get isCancelled => status == HistoryStatus.cancelled;
  bool get isPending => status == HistoryStatus.pending;
  Duration? get processingTime => completionDate?.difference(orderDate);
  double get finalAmount => totalSum - (discountApplied ?? 0);
}