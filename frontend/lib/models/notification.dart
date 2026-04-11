enum NotificationType { otherUpdate, promotion, system }

NotificationType notificationTypeFromString(String type) {
  return NotificationType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => NotificationType.otherUpdate,
  );
}

class AppNotification {
  final int id;
  final int userId;
  final String message;
  final NotificationType notificationType;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.metadata,
    required this.createdAt,
    this.sentAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        message: json['message'] as String? ?? '',
        notificationType: notificationTypeFromString(json['type'] as String? ?? 'otherUpdate'),
        isRead: json['is_read'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      );

  bool get isUnread => !isRead;
}
