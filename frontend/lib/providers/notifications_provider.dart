import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/notification_api_service.dart';
import '../models/notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({this.notifications = const [], this.isLoading = false, this.error});

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationApiService _api;

  NotificationsNotifier({NotificationApiService? api})
      : _api = api ?? NotificationApiService(),
        super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notifications = await _api.getNotifications()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = NotificationsState(notifications: notifications);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    final target = state.notifications.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return;
    try {
      await _api.markAsRead(id);
      state = state.copyWith(
        notifications: [
          for (final n in state.notifications)
            if (n.id == id)
              AppNotification(
                id: n.id,
                userId: n.userId,
                message: n.message,
                notificationType: n.notificationType,
                isRead: true,
                metadata: n.metadata,
                createdAt: n.createdAt,
                sentAt: n.sentAt,
                readAt: DateTime.now(),
              )
            else
              n,
        ],
      );
    } catch (_) {
      // не критично — просто оставляем как непрочитанное
    }
  }

  void setNotifications(List<AppNotification> notifications) {
    state = NotificationsState(notifications: notifications);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, clearError: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const NotificationsState();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
