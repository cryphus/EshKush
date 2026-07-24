class Review {
  final int id;
  final int pointId;
  final int userId;
  final String? userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.pointId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        pointId: json['point_id'] as int,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String?,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
