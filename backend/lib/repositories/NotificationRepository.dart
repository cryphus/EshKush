import 'package:postgres/postgres.dart' hide Notification;
import 'BaseRepository.dart';
import '../model/entities/Notification.dart';
import '../model/enums/NotificationType.dart';
import '../utils/AppException.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository(PostgreSQLConnection connection) : super(connection);

  Future<Notification?> findById(int notificationId) async {
    final result = await queryOne(
      'SELECT * FROM notifications WHERE id = @id',
      params: {'id': notificationId},
    );
    return result == null ? null : Notification.fromJson(result);
  }

  Future<Notification> create(Notification notification) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO notifications (
          user_id, message, type, is_read, metadata,
          created_at, sent_at, read_at
        )
        VALUES (
          @userId, @message, @type::notification_type,
          @isRead, @metadata, @createdAt, @sentAt, @readAt
        )
        RETURNING *
        ''',
        params: {
          'userId': notification.userId,
          'message': notification.message,
          'type': notification.notificationType.toString().split('.').last,
          'isRead': notification.isRead,
          'metadata': notification.metadata,
          'createdAt': notification.createdAt,
          'sentAt': notification.sentAt,
          'readAt': notification.readAt,
        },
      );

      if (result == null) {
        throw const InternalServerException();
      }

      return Notification.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Notification>> findByUserId(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM notifications WHERE user_id = @userId ORDER BY created_at DESC',
        params: {'userId': userId},
      );
      return results.map((map) => Notification.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Notification>> findByType(NotificationType type) async {
    try {
      final results = await query(
        'SELECT * FROM notifications WHERE type = @type::notification_type ORDER BY created_at DESC',
        params: {'type': type.toString().split('.').last},
      );
      return results.map((map) => Notification.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Notification>> findByUserIdAndType(
    int userId,
    NotificationType type,
  ) async {
    final results = await query(
      '''
      SELECT *
      FROM notifications
      WHERE user_id = @userId AND type = @type::notification_type
      ORDER BY created_at DESC
      ''',
      params: {
        'userId': userId,
        'type': type.toString().split('.').last,
      },
    );
    return results.map((map) => Notification.fromJson(map)).toList();
  }

  Future<List<Notification>> findUnread(int userId) async {
    try {
      final results = await query(
        'SELECT * FROM notifications WHERE user_id = @userId AND is_read = false ORDER BY created_at DESC',
        params: {'userId': userId},
      );
      return results.map((map) => Notification.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> existsByIdAndUserId({
    required int notificationId,
    required int userId,
  }) async {
    final result = await queryOne(
      '''
      SELECT 1
      FROM notifications
      WHERE id = @notificationId AND user_id = @userId
      LIMIT 1
      ''',
      params: {
        'notificationId': notificationId,
        'userId': userId,
      },
    );
    return result != null;
  }

  Future<List<Notification>> findRecent({int limit = 100}) async {
    try {
      final results = await query(
        'SELECT * FROM notifications ORDER BY created_at DESC LIMIT @limit',
        params: {'limit': limit},
      );
      return results.map((map) => Notification.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await query(
        '''
        UPDATE notifications 
        SET is_read = true, 
            read_at = NOW()
        WHERE id = @notificationId
        ''',
        params: {'notificationId': notificationId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsSent(int notificationId) async {
    try {
      await query(
        '''
        UPDATE notifications 
        SET sent_at = NOW()
        WHERE id = @notificationId
        ''',
        params: {'notificationId': notificationId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
