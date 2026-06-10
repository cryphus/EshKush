import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:backend/repositories/NotificationRepository.dart';
import 'package:backend/model/entities/Notification.dart' as notif;
import 'package:backend/model/enums/NotificationType.dart';

import '../../helpers/TestDb.dart';
import '../../helpers/TestFixtures.dart';

void main() {
  late PostgreSQLConnection conn;
  late NotificationRepository repo;
  late int userId;

  setUpAll(() async {
    conn = await TestDb.connect();
    repo = NotificationRepository(conn);
    userId = await TestFixtures.createUser(conn);
  });

  setUp(() async => TestDb.truncate(conn, ['notifications']));

  tearDownAll(() async => TestDb.close());

  notif.Notification _notification({
    String message = 'Тестовое уведомление',
    NotificationType type = NotificationType.system,
    bool isRead = false,
  }) =>
      notif.Notification(
        id: 0,
        userId: userId,
        message: message,
        notificationType: type,
        isRead: isRead,
        createdAt: DateTime.now(),
      );

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('создаёт уведомление с id > 0', () async {
      final result = await repo.create(_notification());
      expect(result.id, greaterThan(0));
      expect(result.userId, userId);
      expect(result.message, 'Тестовое уведомление');
    });

    test('isRead по умолчанию false', () async {
      final result = await repo.create(_notification());
      expect(result.isRead, isFalse);
    });

    test('сохраняет тип уведомления', () async {
      final result = await repo.create(_notification(type: NotificationType.promotion));
      expect(result.notificationType, NotificationType.promotion);
    });
  });

  // ── findByUserId ──────────────────────────────────────────────────────────
  group('findByUserId', () {
    test('возвращает уведомления пользователя', () async {
      await repo.create(_notification(message: 'Msg1'));
      await repo.create(_notification(message: 'Msg2'));
      expect((await repo.findByUserId(userId)).length, 2);
    });

    test('возвращает пустой список если уведомлений нет', () async {
      expect(await repo.findByUserId(999999), isEmpty);
    });
  });

  // ── findByType ────────────────────────────────────────────────────────────
  group('findByType', () {
    test('возвращает только уведомления заданного типа', () async {
      await repo.create(_notification(type: NotificationType.system));
      await repo.create(_notification(type: NotificationType.promotion));
      final result = await repo.findByType(NotificationType.system);
      expect(result.every((n) => n.notificationType == NotificationType.system), isTrue);
    });
  });

  // ── findUnread ────────────────────────────────────────────────────────────
  group('findUnread', () {
    test('возвращает только непрочитанные уведомления', () async {
      await repo.create(_notification(isRead: false));
      final created = await repo.create(_notification(isRead: false));
      await repo.markAsRead(created.id);
      final unread = await repo.findUnread(userId);
      expect(unread.every((n) => !n.isRead), isTrue);
    });
  });

  // ── findRecent ────────────────────────────────────────────────────────────
  group('findRecent', () {
    test('возвращает не более limit записей', () async {
      for (var i = 0; i < 5; i++) {
        await repo.create(_notification(message: 'Msg$i'));
      }
      expect((await repo.findRecent(limit: 3)).length, 3);
    });
  });

  // ── markAsRead ────────────────────────────────────────────────────────────
  group('markAsRead', () {
    test('помечает уведомление как прочитанное', () async {
      final created = await repo.create(_notification());
      await repo.markAsRead(created.id);
      final unread = await repo.findUnread(userId);
      expect(unread.any((n) => n.id == created.id), isFalse);
    });
  });
}
