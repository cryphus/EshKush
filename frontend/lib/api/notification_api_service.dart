import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/notification.dart';

class NotificationApiService {
  final Dio _dio = ApiClient().dio;

  /// Получить уведомления пользователя
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications/');
      return (response.data as List).map((j) => AppNotification.fromJson(j)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
