import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/services/NotificationService.dart';
import 'package:backend/repositories/NotificationRepository.dart';
import 'package:backend/model/entities/Notification.dart';
import 'package:backend/model/enums/NotificationType.dart';

import 'NotificationServiceTest.mocks.dart';

@GenerateMocks([NotificationRepository])
void main() {
  late MockNotificationRepository repo;
  late NotificationService sut;

  setUpAll(() => AppConfig.initForTesting());
  setUp(() {
    repo = MockNotificationRepository();
    sut  = NotificationService(repo);
  });

  Notification _notif({int id = 1, int userId = 1, bool isRead = false}) =>
      Notification(
        id: id, userId: userId,
        message: 'Test notification',
        notificationType: NotificationType.otherUpdate,
        isRead: isRead,
        createdAt: DateTime(2024),
      );

  group('createNotification', () {
    test('создаёт уведомление и делегирует в репозиторий', () async {
      when(repo.create(any)).thenAnswer((_) async => _notif());
      final result = await sut.createNotification(
        userId: 1,
        message: 'Your order is ready',
        type: NotificationType.otherUpdate,
      );
      expect(result.userId, 1);
      verify(repo.create(any)).called(1);
    });
  });

  group('getUserNotifications', () {
    test('возвращает уведомления пользователя', () async {
      when(repo.findByUserId(1)).thenAnswer((_) async => [_notif(), _notif(id: 2)]);
      final result = await sut.getUserNotifications(1);
      expect(result.length, 2);
    });
  });

  group('getUnreadNotifications', () {
    test('возвращает непрочитанные уведомления', () async {
      when(repo.findUnread(1)).thenAnswer((_) async => [_notif(isRead: false)]);
      final result = await sut.getUnreadNotifications(1);
      expect(result.length, 1);
    });
  });

  group('getNotificationsByType', () {
    test('возвращает уведомления по типу', () async {
      when(repo.findByType(NotificationType.otherUpdate))
          .thenAnswer((_) async => [_notif()]);
      final result = await sut.getNotificationsByType(NotificationType.otherUpdate);
      expect(result.length, 1);
    });
  });

  group('markNotificationAsRead', () {
    test('делегирует в репозиторий', () async {
      when(repo.markAsRead(1)).thenAnswer((_) async {});
      await expectLater(sut.markNotificationAsRead(1), completes);
      verify(repo.markAsRead(1)).called(1);
    });
  });

  group('markNotificationAsSent', () {
    test('делегирует в репозиторий', () async {
      when(repo.markAsSent(1)).thenAnswer((_) async {});
      await expectLater(sut.markNotificationAsSent(1), completes);
      verify(repo.markAsSent(1)).called(1);
    });
  });
}
