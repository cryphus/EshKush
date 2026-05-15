import '../model/entities/Notification.dart';
import '../model/enums/NotificationType.dart';
import '../repositories/NotificationRepository.dart';

class NotificationService {
  final NotificationRepository _repository;

  NotificationService(this._repository);

  Future<Notification> createNotification({
    required int userId,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = Notification(
      id: 0,
      userId: userId,
      message: message,
      notificationType: type,
      metadata: metadata ?? {},
      isRead: false,
      createdAt: DateTime.now(),
    );

    return await _repository.create(notification);
  }

  Future<List<Notification>> getUserNotifications(int userId) async {
    return await _repository.findByUserId(userId);
  }

  Future<Notification?> getNotificationById(int notificationId) async {
    return await _repository.findById(notificationId);
  }

  Future<List<Notification>> getNotificationsByType(NotificationType type) async {
    return await _repository.findByType(type);
  }

  Future<List<Notification>> getUserNotificationsByType(
    int userId,
    NotificationType type,
  ) async {
    return await _repository.findByUserIdAndType(userId, type);
  }

  Future<List<Notification>> getUnreadNotifications(int userId) async {
    return await _repository.findUnread(userId);
  }

  Future<bool> isNotificationOwnedByUser({
    required int notificationId,
    required int userId,
  }) async {
    return await _repository.existsByIdAndUserId(
      notificationId: notificationId,
      userId: userId,
    );
  }

  Future<List<Notification>> getRecentNotifications({int limit = 100}) async {
    return await _repository.findRecent(limit: limit);
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    await _repository.markAsRead(notificationId);
  }

  Future<void> markNotificationAsSent(int notificationId) async {
    await _repository.markAsSent(notificationId);
  }
} 
