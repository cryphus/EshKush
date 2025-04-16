class PointReview {
  final int id;
  final int pointId;
  final int userId;
  double rating;
  String? comment;
  final DateTime reviewDate;

  PointReview({
    required this.id,
    required this.pointId,
    required this.userId,
    required this.reviewDate,
    this.rating = 0.0,
    this.comment,
  }) {
    _validate();
  }

  void _validate() {
    if (id <= 0) {
      throw ArgumentError('ID отзыва должен быть положительным числом');
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
      id: json['id'] as int,
      pointId: json['point_id'] as int,
      userId: json['user_id'] as int,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      reviewDate: DateTime.parse(json['review_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'point_id': pointId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'review_date': reviewDate.toIso8601String(),
    };
  }

  PointReview copyWith({
    int? id,
    int? pointId,
    int? userId,
    double? rating,
    String? comment,
    DateTime? reviewDate,
  }) {
    return PointReview(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewDate: reviewDate ?? this.reviewDate,
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
          reviewDate == other.reviewDate;

  @override
  int get hashCode =>
      id.hashCode ^
      pointId.hashCode ^
      userId.hashCode ^
      rating.hashCode ^
      comment.hashCode ^
      reviewDate.hashCode;

  @override
  String toString() =>
      'PointReview(id: $id, pointId: $pointId, userId: $userId, ';
}