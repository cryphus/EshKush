import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/review.dart';

class ReviewApiService {
  final Dio _dio = ApiClient().dio;

  /// Отзывы конкретной точки.
  Future<List<Review>> getByPoint(int pointId) async {
    try {
      final response = await _dio.get('/reviews/point/$pointId');
      final list = response.data as List;
      return list.map((j) => Review.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Оставить отзыв о точке (требует авторизации — user_id берётся из JWT).
  Future<Review> create({
    required int pointId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post('/reviews/', data: {
        'point_id': pointId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
