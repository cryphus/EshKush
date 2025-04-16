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
      userId: json['userId'] as int,
      message: json['message'] as String,
      notificationType: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.otherUpdate,
      ),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'type': notificationType.toString().split('.').last,
      'isRead': isRead,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
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
