import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/NotificationController.dart';
import 'package:backend/services/NotificationService.dart';
import 'package:backend/model/entities/Notification.dart';
import 'package:backend/model/enums/NotificationType.dart';

import 'NotificationControllerTest.mocks.dart';

@GenerateMocks([NotificationService])
void main() {
  late MockNotificationService notifService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    notifService = MockNotificationService();
    handler = NotificationController(notifService).router.call;
  });

  Notification _notif({int id = 1}) => Notification(
    id: id,
    userId: 1,
    message: 'Test notification',
    notificationType: NotificationType.otherUpdate,
    isRead: false,
    createdAt: DateTime(2024),
  );

  final _authUser = <String, Object>{'id': 1, 'role': 'user'};

  Map<String, Object> _ctx(Map<String, Object>? user) =>
      user != null ? {'user': user} : {};

  Request _get(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: _ctx(user));

  Request _post(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'},
          context: _ctx(user));

  // ── GET / (recent) ────────────────────────────────────────────────────────
  group('GET /', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get(''));
      expect(resp.statusCode, 401);
    });

    test('200 с авторизацией', () async {
      when(notifService.getRecentNotifications(limit: anyNamed('limit')))
          .thenAnswer((_) async => [_notif()]);
      final resp = await handler(_get('', user: _authUser));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /user ─────────────────────────────────────────────────────────────
  group('GET /user', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('user'));
      expect(resp.statusCode, 401);
    });

    test('400 если userId не указан', () async {
      final resp = await handler(_get('user', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает уведомления пользователя', () async {
      when(notifService.getUserNotifications(1)).thenAnswer((_) async => [_notif()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/user?userId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /unread ───────────────────────────────────────────────────────────
  group('GET /unread', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('unread'));
      expect(resp.statusCode, 401);
    });

    test('400 если userId не указан', () async {
      final resp = await handler(_get('unread', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает непрочитанные', () async {
      when(notifService.getUnreadNotifications(1)).thenAnswer((_) async => [_notif()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/unread?userId=1'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── GET /type ─────────────────────────────────────────────────────────────
  group('GET /type', () {
    test('401 без авторизации', () async {
      final resp = await handler(_get('type'));
      expect(resp.statusCode, 401);
    });

    test('400 если type не указан', () async {
      final resp = await handler(_get('type', user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 возвращает уведомления по типу', () async {
      when(notifService.getNotificationsByType(NotificationType.otherUpdate))
          .thenAnswer((_) async => [_notif()]);
      final resp = await handler(Request('GET',
          Uri.parse('http://localhost/type?type=otherUpdate'),
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /read ────────────────────────────────────────────────────────────
  group('POST /read', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('read', {}));
      expect(resp.statusCode, 401);
    });

    test('400 если notificationId не указан', () async {
      final resp = await handler(_post('read', {}, user: _authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 при отметке как прочитанное', () async {
      when(notifService.markNotificationAsRead(1)).thenAnswer((_) async {});
      final resp = await handler(Request('POST',
          Uri.parse('http://localhost/read?notificationId=1'),
          body: '',
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });

  // ── POST /sent ────────────────────────────────────────────────────────────
  group('POST /sent', () {
    test('401 без авторизации', () async {
      final resp = await handler(_post('sent', {}));
      expect(resp.statusCode, 401);
    });

    test('200 при отметке как отправленное', () async {
      when(notifService.markNotificationAsSent(1)).thenAnswer((_) async {});
      final resp = await handler(Request('POST',
          Uri.parse('http://localhost/sent?notificationId=1'),
          body: '',
          context: _ctx(_authUser)));
      expect(resp.statusCode, 200);
    });
  });
}
