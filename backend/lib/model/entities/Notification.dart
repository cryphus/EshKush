import 'package:backend/model/enums/NotificationType.dart';

class Notification {
  final int id;
  final int userId;
  String message;
  NotificationType notificationType;
  bool isRead;
  final Map<String, dynamic> metadata;
  DateTime createdAt;
  DateTime? sentAt;
  DateTime? readAt;

  Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.notificationType,
    this.isRead = false,
    this.metadata = const {},
    DateTime? createdAt,
    this.sentAt,
    this.readAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (message.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      message: json['message'] as String,
      notificationType: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.otherUpdate,
      ),
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at'] as String),
      sentAt: json['sent_at'] != null 
          ? (json['sent_at'] is DateTime 
              ? json['sent_at'] as DateTime
              : DateTime.parse(json['sent_at'] as String))
          : null,
      readAt: json['read_at'] != null 
          ? (json['read_at'] is DateTime 
              ? json['read_at'] as DateTime
              : DateTime.parse(json['read_at'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'type': notificationType.toString().split('.').last,
      'is_read': isRead,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  void markAsRead() {
    isRead = true;
    readAt = DateTime.now();
  }

  void markAsSent() {
    sentAt = DateTime.now();
  }

  bool get isUnread => !isRead;
  bool get isSent => sentAt != null;
  Duration get age => DateTime.now().difference(createdAt);
}
