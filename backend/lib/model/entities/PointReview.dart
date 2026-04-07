import '../../utils/ValidationUtils.dart';

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
     _sanitize();
     _validate();
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
    if (!rating.isFinite || rating < 0 || rating > 5) {
      throw ArgumentError('Некорректный ID');
    }
    // Разрешаем небольшой временной дрейф (5 минут), но защищаемся от явного будущего времени
    if (createdAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      throw ArgumentError('Дата создания не может быть в будущем');
    }
    if (comment != null && comment!.length > ValidationUtils.maxDescriptionLength) {
      throw ArgumentError('Комментарий не должен превышать 1000 символов');
    }
  }

  void _sanitize() {
    if (comment != null) {
      final sanitized = ValidationUtils.sanitizeString(comment!);
      comment = sanitized.isEmpty ? null : sanitized;
    }
  }

  void updateRating(double newRating) {
    if (!newRating.isFinite || newRating < 0 || newRating > 5) {
      throw ArgumentError('Некорректный ID');
    }
    rating = newRating;
  }

  void updateComment(String? newComment) {
    if (newComment == null) {
      comment = null;
      return;
    }
    final sanitized = ValidationUtils.sanitizeString(newComment);
    if (sanitized.isEmpty) {
      comment = null;
      return;
    }
    if (sanitized.length > ValidationUtils.maxDescriptionLength) {
      throw ArgumentError('Комментарий не должен превышать 1000 символов');
    }
    comment = sanitized;
  }

  factory PointReview.fromJson(Map<String, dynamic> json) {
    final rawComment = json['comment'];
    String? sanitizedComment;
    if (rawComment != null) {
      final s = ValidationUtils.sanitizeString(rawComment.toString());
      sanitizedComment = s.isEmpty ? null : s;
    }
    return PointReview(
      id: int.parse(json['id'].toString()),
      pointId: int.parse(json['point_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      rating: double.parse(json['rating'].toString()),
      comment: sanitizedComment,
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