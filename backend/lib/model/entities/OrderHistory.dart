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
    int _parseInt(dynamic v) => v == null ? 0 : int.parse(v.toString());
    double _parseDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.parse(v.toString()));
    DateTime _parseDate(dynamic v) => v is DateTime ? v : DateTime.parse(v.toString());

    final statusStr = (json['status'] ?? 'pending').toString();
    final status = HistoryStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => HistoryStatus.pending,
    );

    return OrderHistory(
      id: _parseInt(json['id']),
      orderId: _parseInt(json['order_id'] ?? json['orderId']),
      pointId: _parseInt(json['point_id'] ?? json['pointId']),
      userId: _parseInt(json['user_id'] ?? json['userId']),
      orderDate: _parseDate(json['order_date'] ?? json['orderDate']),
      completionDate: json['completion_date'] != null
          ? _parseDate(json['completion_date'])
          : (json['completionDate'] != null ? _parseDate(json['completionDate']) : null),
      totalSum: _parseDouble(json['total_sum'] ?? json['totalSum']),
      status: status,
      receiptLink: (json['receipt_link'] ?? json['receiptLink'])?.toString(),
      discountApplied: json['discount_applied'] != null
          ? _parseDouble(json['discount_applied'])
          : (json['discountApplied'] != null ? _parseDouble(json['discountApplied']) : null),
      promoCodeUsed: (json['promo_code_used'] ?? json['promoCodeUsed'])?.toString(),
      co2Saved: json['co2_saved'] != null
          ? _parseInt(json['co2_saved'])
          : (json['co2Saved'] != null ? _parseInt(json['co2Saved']) : null),
      notes: (json['notes'])?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'point_id': pointId,
      'user_id': userId,
      'order_date': orderDate.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'total_sum': totalSum,
      'status': status.toString().split('.').last,
      'receipt_link': receiptLink,
      'discount_applied': discountApplied,
      'promo_code_used': promoCodeUsed,
      'co2_saved': co2Saved,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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