import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import '../config/AppConfig.dart';
import '../services/AuthService.dart';
import '../services/CacheService.dart';
import '../utils/RequestBodyUtils.dart';
import '../utils/RequestContextUtils.dart';

/// Local presentation tools. Never available unless DEMO_MODE=true.
class DemoController {
  final AuthService auth;
  final PostgreSQLConnection db;
  bool _resetting = false;
  DemoController(this.auth, this.db);

  Handler get router {
    final routes = Router();
    routes.get('/status', _status);
    routes.post('/session', _session);
    routes.get('/state', _state);
    routes.post('/favorite', _favorite);
    routes.post('/reset', _reset);
    final mediaDir = Directory('/app/public/demo/media').existsSync()
        ? '/app/public/demo/media'
        : 'public/demo/media';
    routes.mount('/media/', createStaticHandler(mediaDir));
    return (request) => AppConfig().isDemo
        ? routes(request)
        : Future.value(Response.notFound('Not found'));
  }

  Response _json(Object value, [int status = 200]) => Response(
    status,
    body: jsonEncode(value),
    headers: {'content-type': 'application/json'},
  );

  Future<List<dynamic>> _rows(
    String sql, [
    Map<String, dynamic>? params,
  ]) async {
    final rows = await db.query(sql, substitutionValues: params);
    return rows.map((row) => row.first).toList();
  }

  Future<Response> _status(Request request) async {
    final counts = await db.query(
      'SELECT (SELECT COUNT(*) FROM products), (SELECT COUNT(*) FROM orders)',
    );
    return _json({
      'mode': 'demo',
      'version': '1.0.0',
      'products': counts.first[0],
      'orders': counts.first[1],
      'services': [
        {
          'id': 'database',
          'name': 'Каталог и заказы',
          'status': 'ready',
          'kind': 'local',
        },
        {
          'id': 'payments',
          'name': 'Оплата и возвраты',
          'status': 'ready',
          'kind': 'simulated',
        },
        {
          'id': 'auth',
          'name': 'Вход и соцсети',
          'status': 'ready',
          'kind': 'simulated',
        },
        {
          'id': 'maps',
          'name': 'Карта заведений',
          'status': 'ready',
          'kind': 'local',
        },
        {
          'id': 'notifications',
          'name': 'Уведомления',
          'status': 'ready',
          'kind': 'local',
        },
        {
          'id': 'support',
          'name': 'Поддержка',
          'status': 'ready',
          'kind': 'simulated',
        },
      ],
    });
  }

  Future<Response> _session(Request request) async {
    final body = await RequestBodyUtils.readJsonObject(request);
    final role = body['role']?.toString() ?? 'user';
    const accounts = {
      'user': ['demo', 'Demo@1234'],
      'partner': ['partner1', 'Partner@1234'],
      'admin': ['adminuser', 'Admin@1234'],
    };
    final account = accounts[role];
    if (account == null)
      return _json({'error': 'Неизвестный демо-профиль'}, 400);
    return _json(
      await auth.login(account[0], account[1], userAgent: 'EshKush Demo'),
    );
  }

  Future<Response> _state(Request request) async {
    final user = RequestContextUtils.getUser(request)!;
    final userId = user['id'];
    final params = <String, dynamic>{'user': userId};
    final scope = user['role'] == 'user'
        ? 'WHERE o.user_id = @user'
        : user['role'] == 'partner'
        ? 'WHERE o.point_id IN (SELECT p.id FROM points p JOIN partners a ON a.id=p.partner_id WHERE a.user_id=@user)'
        : '';
    final products = await _rows(
      'SELECT row_to_json(p) FROM products p ORDER BY p.id',
    );
    final points = await _rows(
      'SELECT row_to_json(p) FROM points p ORDER BY p.id',
    );
    final cities = await _rows(
      'SELECT row_to_json(c) FROM cities c ORDER BY c.id',
    );
    final orders = await _rows(
      'SELECT row_to_json(o) FROM orders o $scope ORDER BY o.date DESC, o.id DESC',
      params,
    );
    final favorites = await db.query(
      'SELECT point_id FROM user_favorites WHERE user_id=@user',
      substitutionValues: params,
    );
    return _json({
      'products': products,
      'points': points,
      'cities': cities,
      'orders': orders,
      'favorites': favorites.map((row) => row.first).toList(),
      'user': {'id': userId, 'role': user['role']},
    });
  }

  Future<Response> _favorite(Request request) async {
    final body = await RequestBodyUtils.readJsonObject(request);
    final point = body['point_id'];
    if (point is! int) return _json({'error': 'Укажите заведение'}, 400);
    final params = {
      'point': point,
      'user': RequestContextUtils.getUserId(request),
    };
    if (body['active'] == true) {
      await db.execute(
        'INSERT INTO user_favorites(user_id,point_id) VALUES (@user,@point) ON CONFLICT DO NOTHING',
        substitutionValues: params,
      );
    } else {
      await db.execute(
        'DELETE FROM user_favorites WHERE user_id=@user AND point_id=@point',
        substitutionValues: params,
      );
    }
    return _json({'saved': body['active'] == true});
  }

  Future<Response> _reset(Request request) async {
    if (RequestContextUtils.getRole(request) != 'admin')
      return _json({'error': 'Только администратор демонстрации'}, 403);
    if (_resetting) return _json({'error': 'Сброс уже выполняется'}, 409);
    _resetting = true;
    try {
      final process = await Process.run(
        '/app/seed-demo',
        [],
        environment: {'DEMO_RESET': 'true'},
        includeParentEnvironment: true,
      );
      if (process.exitCode != 0)
        return _json({'error': 'Не удалось восстановить данные'}, 500);
      await CacheService().flushAll();
      return _json({'reset': true});
    } finally {
      _resetting = false;
    }
  }
}
