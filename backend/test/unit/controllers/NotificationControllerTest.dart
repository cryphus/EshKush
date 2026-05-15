import 'dart:convert';

import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/NotificationController.dart';
import 'package:backend/model/entities/Notification.dart';
import 'package:backend/model/enums/NotificationType.dart';
import 'package:backend/services/NotificationService.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

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

  Notification notif({int id = 1}) => Notification(
        id: id,
        userId: 1,
        message: 'Test notification',
        notificationType: NotificationType.otherUpdate,
        isRead: false,
        createdAt: DateTime(2024),
      );

  const authUser = <String, Object>{'id': 1, 'role': 'user'};
  const adminUser = <String, Object>{'id': 999, 'role': 'admin'};

  Map<String, Object> ctx(Map<String, Object>? user) => user != null ? {'user': user} : {};

  Request getReq(String path, {Map<String, Object>? user}) =>
      Request('GET', Uri.parse('http://localhost/$path'), context: ctx(user));

  Request postReq(String path, Map<String, dynamic> body, {Map<String, Object>? user}) =>
      Request(
        'POST',
        Uri.parse('http://localhost/$path'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
        context: ctx(user),
      );

  group('GET / (recent)', () {
    test('401 without auth', () async {
      final resp = await handler(getReq(''));
      expect(resp.statusCode, 401);
    });

    test('200 with auth (user gets own notifications)', () async {
      when(notifService.getUserNotifications(1)).thenAnswer((_) async => [notif()]);
      final resp = await handler(getReq('', user: authUser));
      expect(resp.statusCode, 200);
    });
  });

  group('GET /user', () {
    test('401 without auth', () async {
      final resp = await handler(getReq('user'));
      expect(resp.statusCode, 401);
    });

    test('200 without query userId uses current user', () async {
      when(notifService.getUserNotifications(1)).thenAnswer((_) async => [notif()]);
      final resp = await handler(getReq('user', user: authUser));
      expect(resp.statusCode, 200);
    });

    test('200 returns notifications for requested own userId', () async {
      when(notifService.getUserNotifications(1)).thenAnswer((_) async => [notif()]);
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/user?userId=1'),
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 200);
    });

    test('403 when user requests чужой userId', () async {
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/user?userId=2'),
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 403);
    });
  });

  group('GET /unread', () {
    test('401 without auth', () async {
      final resp = await handler(getReq('unread'));
      expect(resp.statusCode, 401);
    });

    test('200 without query userId uses current user', () async {
      when(notifService.getUnreadNotifications(1)).thenAnswer((_) async => [notif()]);
      final resp = await handler(getReq('unread', user: authUser));
      expect(resp.statusCode, 200);
    });

    test('200 returns unread for own userId', () async {
      when(notifService.getUnreadNotifications(1)).thenAnswer((_) async => [notif()]);
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/unread?userId=1'),
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 200);
    });

    test('403 when user requests unread of another user', () async {
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/unread?userId=2'),
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 403);
    });
  });

  group('GET /type', () {
    test('401 without auth', () async {
      final resp = await handler(getReq('type'));
      expect(resp.statusCode, 401);
    });

    test('400 when type not provided', () async {
      final resp = await handler(getReq('type', user: authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 for user with scoped by userId data', () async {
      when(
        notifService.getUserNotificationsByType(1, NotificationType.otherUpdate),
      ).thenAnswer((_) async => [notif()]);
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/type?type=otherUpdate'),
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 200);
    });

    test('200 for admin with global by-type data', () async {
      when(notifService.getNotificationsByType(NotificationType.otherUpdate))
          .thenAnswer((_) async => [notif()]);
      final resp = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/type?type=otherUpdate'),
          context: ctx(adminUser),
        ),
      );
      expect(resp.statusCode, 200);
    });
  });

  group('POST /read', () {
    test('401 without auth', () async {
      final resp = await handler(postReq('read', {}));
      expect(resp.statusCode, 401);
    });

    test('400 when notificationId is missing', () async {
      final resp = await handler(postReq('read', {}, user: authUser));
      expect(resp.statusCode, greaterThanOrEqualTo(400));
    });

    test('200 when owner marks read', () async {
      when(
        notifService.isNotificationOwnedByUser(notificationId: 1, userId: 1),
      ).thenAnswer((_) async => true);
      when(notifService.markNotificationAsRead(1)).thenAnswer((_) async {});

      final resp = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/read?notificationId=1'),
          body: '',
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 200);
    });

    test('403 when not owner', () async {
      when(
        notifService.isNotificationOwnedByUser(notificationId: 1, userId: 1),
      ).thenAnswer((_) async => false);

      final resp = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/read?notificationId=1'),
          body: '',
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 403);
    });
  });

  group('POST /sent', () {
    test('401 without auth', () async {
      final resp = await handler(postReq('sent', {}));
      expect(resp.statusCode, 401);
    });

    test('200 when owner marks sent', () async {
      when(
        notifService.isNotificationOwnedByUser(notificationId: 1, userId: 1),
      ).thenAnswer((_) async => true);
      when(notifService.markNotificationAsSent(1)).thenAnswer((_) async {});
      final resp = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/sent?notificationId=1'),
          body: '',
          context: ctx(authUser),
        ),
      );
      expect(resp.statusCode, 200);
    });
  });
}
