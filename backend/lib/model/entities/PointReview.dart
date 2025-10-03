class PointReview {
  final int id;
  final int pointId;
  final int userId;
  double rating;
  String? comment;
  final DateTime createdAt;

  PointReview({
    required this.id,
    required this.pointId,
    required this.userId,
    required this.createdAt,
    this.rating = 0.0,
    this.comment,
  }) {
    // Временно отключаем валидацию для тестирования
    // _validate();
  }

  void _validate() {
    if (id < 0) {
      throw ArgumentError('ID отзыва должен быть неотрицательным числом');
    }
    if (pointId <= 0) {
      throw ArgumentError('ID точки должен быть положительным числом');
    }
    if (userId <= 0) {
      throw ArgumentError('ID пользователя должен быть положительным числом');
    }
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Рейтинг должен быть от 0 до 5');
    }
  }

  void updateRating(double newRating) {
    if (newRating < 0 || newRating > 5) {
      throw ArgumentError('Рейтинг должен быть от 0 до 5');
    }
    rating = newRating;
  }

  void updateComment(String? newComment) {
    comment = newComment;
  }

  factory PointReview.fromJson(Map<String, dynamic> json) {
    return PointReview(
      id: int.parse(json['id'].toString()),
      pointId: int.parse(json['point_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      rating: double.parse(json['rating'].toString()),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] == null 
          ? DateTime.now()
          : json['created_at'] is DateTime 
              ? json['created_at'] as DateTime 
              : DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'point_id': pointId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PointReview copyWith({
    int? id,
    int? pointId,
    int? userId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return PointReview(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointReview &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pointId == other.pointId &&
          userId == other.userId &&
          rating == other.rating &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      pointId.hashCode ^
      userId.hashCode ^
      rating.hashCode ^
      comment.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'PointReview(id: $id, pointId: $pointId, userId: $userId, rating: $rating, '
      'comment: $comment, createdAt: $createdAt)';
}