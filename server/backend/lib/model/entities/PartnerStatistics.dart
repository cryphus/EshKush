class PartnerStatistics {
  final int id;
  final int partnerId;
  final int pointId;
  int totalOrders;
  double totalRevenue;
  int totalCancel;
  double averageRating;
  int totalReviews;
  final DateTime createdAt;
  final DateTime? updatedAt;
  bool isActive;

  PartnerStatistics({
    required this.id,
    required this.partnerId,
    required this.pointId,
    required this.totalCancel,
    required this.totalOrders,
    required this.createdAt,
    this.totalRevenue = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.updatedAt,
    this.isActive = true,
  }) {
    _validate();
  }

  void _validate() {
    if (id < 0) {
      throw ArgumentError('ID статистики не может быть отрицательным');
    }
    if (partnerId <= 0) {
      throw ArgumentError('ID партнера должен быть положительным числом');
    }
    if (pointId <= 0) {
      throw ArgumentError('ID точки должен быть положительным числом');
    }
    if (totalOrders < 0) {
      throw ArgumentError('Общее количество заказов не может быть отрицательным');
    }
    if (totalRevenue < 0) {
      throw ArgumentError('Общая выручка не может быть отрицательной');
    }
    if (totalCancel < 0) {
      throw ArgumentError('Количество отмен не может быть отрицательным');
    }
    if (averageRating < 0 || averageRating > 5) {
      throw ArgumentError('Средний рейтинг должен быть от 0 до 5');
    }
    if (totalReviews < 0) {
      throw ArgumentError('Общее количество отзывов не может быть отрицательным');
    }
  }

  void addOrder(double revenue) {
    if (revenue < 0) {
      throw ArgumentError('Выручка не может быть отрицательной');
    }
    totalOrders++;
    totalRevenue += revenue;
  }

  void addCancel() {
    totalCancel++;
  }

  void updateRating(double newRating) {
    if (newRating < 0 || newRating > 5) {
      throw ArgumentError('Рейтинг должен быть от 0 до 5');
    }
    averageRating = ((averageRating * totalReviews) + newRating) / (totalReviews + 1);
    totalReviews++;
  }

  void deactivate() {
    isActive = false;
  }

  void activate() {
    isActive = true;
  }

  factory PartnerStatistics.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) => v is DateTime ? v : DateTime.parse(v.toString());
    double _parseDouble(dynamic v) => v == null ? 0.0 : (v is num ? v.toDouble() : double.parse(v.toString()));
    int _parseInt(dynamic v) => v == null ? 0 : int.parse(v.toString());

    return PartnerStatistics(
      id: _parseInt(json['id']),
      partnerId: _parseInt(json['partner_id']),
      pointId: _parseInt(json['point_id']),
      totalOrders: _parseInt(json['total_orders']),
      totalRevenue: _parseDouble(json['total_revenue']),
      totalCancel: _parseInt(json['total_cancel']),
      averageRating: _parseDouble(json['average_rating']),
      totalReviews: _parseInt(json['total_reviews']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: json['updated_at'] != null ? _parseDate(json['updated_at']) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'point_id': pointId,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'total_cancel': totalCancel,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  PartnerStatistics copyWith({
    int? id,
    int? partnerId,
    int? pointId,
    int? totalOrders,
    double? totalRevenue,
    int? totalCancel,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PartnerStatistics(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      pointId: pointId ?? this.pointId,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCancel: totalCancel ?? this.totalCancel,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerStatistics &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          partnerId == other.partnerId &&
          pointId == other.pointId &&
          totalOrders == other.totalOrders &&
          totalRevenue == other.totalRevenue &&
          totalCancel == other.totalCancel &&
          averageRating == other.averageRating &&
          totalReviews == other.totalReviews &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      partnerId.hashCode ^
      pointId.hashCode ^
      totalOrders.hashCode ^
      totalRevenue.hashCode ^
      totalCancel.hashCode ^
      averageRating.hashCode ^
      totalReviews.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'PartnerStatistics(id: $id, partnerId: $partnerId, pointId: $pointId, '
      'totalOrders: $totalOrders, totalRevenue: $totalRevenue, totalCancel: $totalCancel, '
      'averageRating: $averageRating, totalReviews: $totalReviews, isActive: $isActive)';
}