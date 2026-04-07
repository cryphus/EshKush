// ignore_for_file: avoid_print
/// EshKush API — интеграционные тесты
/// Запуск: dart test/ApiTest.dart
/// Авто-запуск при старте сервера: задать переменную RUN_TESTS=true
library;

import 'dart:convert';
import 'dart:io';

// ─── Config ──────────────────────────────────────────────────────────────────
const _base = 'http://localhost:8080';

// ─── Состояние ───────────────────────────────────────────────────────────────
int _pass = 0;
int _fail = 0;
String _section = '';
final List<String> _failures = [];

// ─── Цвета ───────────────────────────────────────────────────────────────────
const _green  = '\x1B[32m';
const _red    = '\x1B[31m';
const _yellow = '\x1B[33m';
const _cyan   = '\x1B[36m';
const _gray   = '\x1B[90m';
const _reset  = '\x1B[0m';
const _bold   = '\x1B[1m';

// ─── HTTP-клиент ─────────────────────────────────────────────────────────────
Future<(int, dynamic)> req(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$_base$path');
    final rq = await client.openUrl(method, uri);
    rq.headers.set('Content-Type', 'application/json');
    rq.headers.set('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      rq.headers.set('Authorization', 'Bearer $token');
    }
    if (body != null) {
      final encoded = utf8.encode(jsonEncode(body));
      rq.headers.contentLength = encoded.length;
      rq.add(encoded);
    }
    final rs = await rq.close();
    final raw = await rs.transform(utf8.decoder).join();
    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      parsed = {'_raw': raw.length > 80 ? raw.substring(0, 80) : raw};
    }
    return (rs.statusCode, parsed);
  } catch (e) {
    return (0, {'_error': e.toString()});
  } finally {
    client.close();
  }
}

// ─── Вспомогательные проверки ────────────────────────────────────────────────
void check(String label, bool ok, {String? detail}) {
  if (ok) {
    _pass++;
    print('  ${_green}ПРОШЁЛ$_reset $label');
  } else {
    _fail++;
    final msg = '[$_section] $label${detail != null ? " — $detail" : ""}';
    _failures.add(msg);
    print('  ${_red}ОШИБКА$_reset $label${detail != null ? "  ${_red}($detail)$_reset" : ""}');
  }
}

void expectStatus(String label, int got, int want) {
  check(label, got == want, detail: 'HTTP $got, ожидался $want');
}

void expectOk(String label, int got) {
  check(label, got >= 200 && got < 300, detail: 'HTTP $got');
}

/// Вывод дополнительной информации о данных (серым цветом, с отступом)
void info(String text) {
  print('     ${_gray}↳ $text$_reset');
}

void section(String name) {
  _section = name;
  print('\n$_cyan$_bold── $name $_reset');
}

// ─── Ожидание готовности сервера ─────────────────────────────────────────────
Future<void> waitForServer({int maxSeconds = 30}) async {
  print('${_yellow}Ожидание сервера по адресу $_base ...$_reset');
  for (var i = 0; i < maxSeconds; i++) {
    try {
      final (s, _) = await req('GET', '/');
      if (s == 200) {
        print('${_green}Сервер готов.$_reset\n');
        return;
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  print('${_red}Сервер не запустился за $maxSeconds с — прерываю.$_reset');
  exit(1);
}

// ─── Вспомогательные методы авторизации ──────────────────────────────────────
Future<String> loginAs(String username, String password) async {
  final (_, b) = await req('POST', '/login',
      body: {'username': username, 'password': password});
  return (b as Map?)?['access_token'] as String? ?? '';
}

Future<String> registerAndLogin(
    String username, String password, String email, String number) async {
  await req('POST', '/auth/register', body: {
    'username': username,
    'password': password,
    'password_confirm': password,
    'email': email,
    'number': number,
  });
  return loginAs(username, password);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
Future<void> main() async {
  print('$_bold${_cyan}═══════════════════════════════════════════$_reset');
  print('$_bold${_cyan}  EshKush API — интеграционные тесты$_reset');
  print('$_bold${_cyan}═══════════════════════════════════════════$_reset\n');

  await waitForServer();

  // Авторизация администратора
  final aT = await loginAs('adminuser', 'Admin@1234');
  if (aT.isEmpty) {
    print('${_red}Не удалось войти как admin — прерываю.$_reset');
    exit(1);
  }

  // Регистрация и авторизация обычного пользователя
  final ts = DateTime.now().millisecondsSinceEpoch;
  final uName = 'tuser$ts';
  final uPhone = '+7999${(ts % 10000000).toString().padLeft(7, "0")}';
  final uT = await registerAndLogin(
    uName, 'Test@1234', '$uName@test.com', uPhone,
  );

  print('${_bold}Аккаунты:$_reset');
  print('  Администратор : adminuser  (токен ${aT.substring(0, 20)}...)');
  print('  Тестовый юзер : $uName / $uPhone  (токен ${uT.isEmpty ? "не получен" : "${uT.substring(0, 20)}..."})');

  // ─── Базовые данные ──────────────────────────────────────────────────
  final (_, partnersList) = await req('GET', '/partners', token: aT);
  final _pl = partnersList as List?;
  final partnerId =
      (_pl != null && _pl.isNotEmpty) ? (_pl.first as Map)['id'] as int : 2;
  final partnerName = (_pl != null && _pl.isNotEmpty)
      ? (_pl.first as Map)['name'] as String? ?? '?'
      : '?';

  final (_, cityList) = await req('GET', '/cities', token: aT);
  final _cl = cityList as List?;
  final cityId =
      (_cl != null && _cl.isNotEmpty) ? (_cl.first as Map)['id'] as int : 1;
  final cityName = (_cl != null && _cl.isNotEmpty)
      ? (_cl.first as Map)['name'] as String? ?? '?'
      : '?';

  print('\n${_bold}Базовые данные:$_reset');
  print('  Партнёр: id=$partnerId, name=$partnerName');
  print('  Город  : id=$cityId, name=$cityName');

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. ОТКРЫТЫЕ ЭНДПОИНТЫ (без токена)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Открытые эндпоинты');

  {
    final (s, b) = await req('GET', '/');
    expectStatus('GET / — корневой маршрут', s, 200);
    info('version=${((b as Map?)?["version"] ?? "?")}');
  }
  {
    final (s, _) = await req('GET', '/swagger/');
    expectOk('GET /swagger/ — документация', s);
  }
  {
    final (s, b) = await req('POST', '/login',
        body: {'username': 'adminuser', 'password': 'Admin@1234'});
    expectStatus('POST /login — корректный логин', s, 200);
    final hasToken = (b as Map?)?.containsKey('access_token') == true;
    check('POST /login → наличие access_token', hasToken);
    if (hasToken) info('access_token получен, expires_in=${(b as Map?)?["expires_in"] ?? "?"}');
  }
  {
    final (s, b) = await req('POST', '/login',
        body: {'username': 'adminuser', 'password': 'неверный_пароль'});
    expectStatus('POST /login — неверный пароль → 401', s, 401);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/login', body: {'username': 'adminuser'});
    check('POST /login — отсутствует password → 4xx', s >= 400);
  }
  {
    final (s, b) = await req('POST', '/auth/register', body: {
      'username': 'adminuser',
      'password': 'Admin@1234',
      'password_confirm': 'Admin@1234',
      'email': 'x@y.com',
      'number': '+70000000009',
    });
    expectStatus('POST /auth/register — дубликат → 409', s, 409);
    info('причина: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/auth/register', body: {
      'username': 'newuser$ts',
      'password': 'Test@1234',
      'password_confirm': 'НЕВЕРНО',
      'email': 'new@test.com',
      'number': '+79990000001',
    });
    check('POST /auth/register — пароли не совпадают → 4xx', s >= 400);
  }
  {
    final (s, _) = await req('POST', '/auth/register', body: {
      'username': 'x',
      'password': 'Test@1234',
      'password_confirm': 'Test@1234',
      'email': 'не-email',
      'number': '+79990000001',
    });
    check('POST /auth/register — некорректный email → 4xx', s >= 400);
  }
  {
    final (s, b) = await req('POST', '/auth/check_user',
        body: {'number': '+79990000001'});
    expectStatus('POST /auth/check_user — телефон существует', s, 200);
    info('exists=${((b as Map?)?["exists"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/auth/check_user', body: {});
    check('POST /auth/check_user — отсутствует поле → 4xx', s >= 400);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ТОКЕН ОБЯЗАТЕЛЕН — без токена → 401
  // ═══════════════════════════════════════════════════════════════════════════
  section('Без токена → 401');

  for (final path in [
    '/users/profile', '/sessions', '/orders', '/favorites',
    '/changes', '/notifications', '/order-history', '/payment-transactions',
  ]) {
    final (s, _) = await req('GET', path);
    expectStatus('GET $path — нет токена', s, 401);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. RBAC — роль user → 403 на закрытых маршрутах
  // ═══════════════════════════════════════════════════════════════════════════
  section('RBAC: роль user → 403');

  if (uT.isNotEmpty) {
    for (final path in [
      '/action-logs', '/error-logs', '/cache',
      '/partner-statistics', '/promo-codes',
      '/point-categories', '/product-categories',
    ]) {
      final (s, _) = await req('GET', path, token: uT);
      expectStatus('GET $path — роль user → 403', s, 403);
    }
  } else {
    check('Токен обычного пользователя (пропускаем RBAC)', false,
        detail: 'регистрация не удалась');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. ПОЛЬЗОВАТЕЛИ / ПРОФИЛЬ / СЕССИИ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Пользователи / Профиль / Сессии');

  {
    final (s, b) = await req('GET', '/users/profile', token: aT);
    expectStatus('GET /users/profile — мой профиль', s, 200);
    final m = b as Map?;
    info('username=${m?["username"]}, email=${m?["email"]}, role=${m?["role"]}');
  }
  {
    final (s, _) = await req('PUT', '/users/profile',
        body: {'email': 'admin_test@eshkush.ru'}, token: aT);
    expectStatus('PUT /users/profile — обновление email', s, 200);
    info('новый email: admin_test@eshkush.ru');
  }
  {
    final (s, b) = await req('PUT', '/users/profile',
        body: {'email': 'это-не-email'}, token: aT);
    check('PUT /users/profile — некорректный email → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, b) = await req('GET', '/sessions', token: aT);
    expectStatus('GET /sessions — список сессий', s, 200);
    final list = b as List?;
    info('активных сессий: ${list?.length ?? 0}');
  }
  {
    final (s, b) = await req('POST', '/profiles',
        body: {'first_name': 'Admin', 'last_name': 'User'}, token: aT);
    check('POST /profiles — создание/уже существует', s == 200 || s == 409);
    info('статус: $s');
  }
  {
    final (s, _) = await req('POST', '/profiles',
        body: {'first_name': 'А'}, token: aT);
    check('POST /profiles — отсутствует last_name → 4xx', s >= 400);
  }
  {
    final (s, b) = await req('GET', '/profiles', token: aT);
    check('GET /profiles — мой профиль', s == 200 || s == 404);
    if (s == 200) {
      final m = b as Map?;
      info('first_name=${m?["first_name"]}, last_name=${m?["last_name"]}');
    }
  }
  {
    final (s, _) = await req('GET', '/profiles/me', token: aT);
    check('GET /profiles/me', s == 200 || s == 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. ГОРОДА
  // ═══════════════════════════════════════════════════════════════════════════
  section('Города');

  {
    final (s, b) = await req('GET', '/cities', token: aT);
    expectStatus('GET /cities — список городов', s, 200);
    info('городов в базе: ${(b as List?)?.length ?? 0}');
  }
  {
    final cityTestName = 'ТестГород$ts';
    final (s, b) = await req('POST', '/cities',
        body: {'name': cityTestName}, token: aT);
    expectOk('POST /cities — создание города', s);
    final _bCity = b as Map?;
    final newCityId = (_bCity != null && _bCity.containsKey('id')) ? _bCity['id'] as int : null;
    info('создан: id=$newCityId, name=$cityTestName');

    if (newCityId != null) {
      final (s2, b2) = await req('GET', '/cities/$newCityId', token: aT);
      expectStatus('GET /cities/$newCityId — получение по id', s2, 200);
      info('name=${((b2 as Map?)?["name"] ?? "?")}');

      final updName = 'Обновлён$ts';
      final (s3, b3) = await req('PUT', '/cities/$newCityId',
          body: {'name': updName}, token: aT);
      expectStatus('PUT /cities/$newCityId — обновление', s3, 200);
      info('новое name=${((b3 as Map?)?["name"] ?? updName)}');

      final (s4, b4) = await req('DELETE', '/cities/$newCityId', token: aT);
      expectStatus('DELETE /cities/$newCityId — удаление', s4, 200);
      info('${((b4 as Map?)?["message"] ?? "удалён")}');
    }
  }
  {
    final (s, b) = await req('POST', '/cities', body: {}, token: aT);
    check('POST /cities — без name → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, b) = await req('GET', '/cities/$cityId', token: aT);
    expectStatus('GET /cities/$cityId — существующий город', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}');
  }
  {
    final (s, _) = await req('GET', '/cities/999999', token: aT);
    expectStatus('GET /cities/999999 — не найден → 404', s, 404);
  }
  {
    final (s, _) = await req('DELETE', '/cities/999999', token: aT);
    expectStatus('DELETE /cities/999999 — не найден → 404', s, 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. ПАРТНЁРЫ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Партнёры');

  {
    final (s, b) = await req('GET', '/partners', token: aT);
    expectStatus('GET /partners — список партнёров', s, 200);
    info('партнёров в базе: ${(b as List?)?.length ?? 0}');
  }
  {
    final pName = 'TestPartner$ts';
    final pEmail = 'tp$ts@test.com';
    final pPhone = '+7999${(ts % 10000000).toString().padLeft(7, "0")}';
    final (s, b) = await req('POST', '/partners', body: {
      'name': pName,
      'user_id': 2,
      'contact_email': pEmail,
      'contact_phone': pPhone,
    }, token: aT);
    expectOk('POST /partners — создание партнёра', s);
    final _bPartner = b as Map?;
    final newPartnerId = (_bPartner != null && _bPartner.containsKey('id')) ? _bPartner['id'] as int : null;
    info('создан: id=$newPartnerId, name=$pName, email=$pEmail');

    if (newPartnerId != null) {
      final (s2, b2) = await req('GET', '/partners/$newPartnerId', token: aT);
      expectStatus('GET /partners/$newPartnerId — получение по id', s2, 200);
      info('name=${((b2 as Map?)?["name"] ?? "?")}');

      final (s3, b3) = await req('PUT', '/partners/$newPartnerId', body: {
        'name': 'UpdatedPartner$ts',
        'user_id': 2,
        'contact_email': 'upd$ts@test.com',
        'contact_phone': pPhone,
      }, token: aT);
      expectStatus('PUT /partners/$newPartnerId — обновление', s3, 200);
      info('новое name=${((b3 as Map?)?["name"] ?? "?")}');

      final (s4, b4) = await req('DELETE', '/partners/$newPartnerId', token: aT);
      expectStatus('DELETE /partners/$newPartnerId — удаление', s4, 200);
      info('${((b4 as Map?)?["message"] ?? "удалён")}');
    }
  }
  {
    final (s, b) = await req('POST', '/partners', body: {}, token: aT);
    check('POST /partners — без обязательных полей → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/partners', body: {
      'name': 'X',
      'user_id': 2,
      'contact_email': 'это-не-email',
    }, token: aT);
    check('POST /partners — некорректный email → 4xx', s >= 400);
  }
  {
    final (s, b) = await req('GET', '/partners/$partnerId', token: aT);
    expectStatus('GET /partners/$partnerId — существующий партнёр', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}, contact_email=${((b as Map?)?["contact_email"] ?? "?")}');
  }
  {
    final (s, _) = await req('GET', '/partners/999999', token: aT);
    expectStatus('GET /partners/999999 — не найден → 404', s, 404);
  }
  {
    final (s, b) = await req('GET', '/partner-settings', token: aT);
    expectStatus('GET /partner-settings — настройки', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. КАТЕГОРИИ ТОЧЕК (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Категории точек');

  int? testPcatId;
  {
    final (s, b) = await req('GET', '/point-categories', token: aT);
    expectStatus('GET /point-categories — список', s, 200);
    info('категорий: ${(b as List?)?.length ?? 0}');
  }
  {
    final catName = 'КатТочки$ts';
    final (s, b) = await req('POST', '/point-categories',
        body: {'name': catName, 'description': 'Тестовая категория'}, token: aT);
    expectOk('POST /point-categories — создание', s);
    final _bPcat = b as Map?;
    testPcatId = (_bPcat != null && _bPcat.containsKey('id')) ? _bPcat['id'] as int : null;
    info('создана: id=$testPcatId, name=$catName');
  }
  {
    final (s, b) = await req('POST', '/point-categories', body: {}, token: aT);
    check('POST /point-categories — без name → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  if (testPcatId != null) {
    final (s, b) = await req('GET', '/point-categories/$testPcatId', token: aT);
    expectStatus('GET /point-categories/$testPcatId — получение', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}');

    final updName = 'КатТочкиОбн$ts';
    final (s2, b2) = await req('PUT', '/point-categories/$testPcatId',
        body: {'name': updName}, token: aT);
    expectStatus('PUT /point-categories/$testPcatId — обновление', s2, 200);
    info('новое name=${((b2 as Map?)?["name"] ?? updName)}');
  }
  {
    final (s, _) = await req('GET', '/point-categories/999999', token: aT);
    expectStatus('GET /point-categories/999999 — не найден → 404', s, 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. КАТЕГОРИИ ПРОДУКТОВ (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Категории продуктов');

  int? testProdcatId;
  {
    final (s, b) = await req('GET', '/product-categories', token: aT);
    expectStatus('GET /product-categories — список', s, 200);
    info('категорий: ${(b as List?)?.length ?? 0}');
  }
  {
    final catName = 'КатПрод$ts';
    final (s, b) = await req('POST', '/product-categories',
        body: {'name': catName, 'description': 'Тестовая'}, token: aT);
    expectOk('POST /product-categories — создание', s);
    final _bProdcat = b as Map?;
    testProdcatId = (_bProdcat != null && _bProdcat.containsKey('id')) ? _bProdcat['id'] as int : null;
    info('создана: id=$testProdcatId, name=$catName');
  }
  {
    final (s, b) = await req('POST', '/product-categories', body: {}, token: aT);
    check('POST /product-categories — без name → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  if (testProdcatId != null) {
    final (s, b) = await req('GET', '/product-categories/$testProdcatId', token: aT);
    expectStatus('GET /product-categories/$testProdcatId — получение', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}');

    final updName = 'КатПродОбн$ts';
    final (s2, b2) = await req('PUT', '/product-categories/$testProdcatId',
        body: {'name': updName}, token: aT);
    expectStatus('PUT /product-categories/$testProdcatId — обновление', s2, 200);
    info('новое name=${((b2 as Map?)?["name"] ?? updName)}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. ТОЧКИ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Точки');

  int? testPointId;
  int? testPointReviewId;
  {
    final (s, b) = await req('GET', '/points', token: aT);
    expectStatus('GET /points — список точек', s, 200);
    info('точек в базе: ${(b as List?)?.length ?? 0}');
  }
  {
    final ptName = 'ТестТочка$ts';
    final (s, b) = await req('POST', '/points', body: {
      'name': ptName,
      'address': 'ул. Тестовая, 1',
      'city_id': cityId,
      'partner_id': partnerId,
      'latitude': 55.75,
      'longitude': 37.62,
      'opening_hours': '09:00',
      'closing_hours': '22:00',
    }, token: aT);
    expectOk('POST /points — создание точки', s);
    final _bPoint = b as Map?;
    testPointId = (_bPoint != null && _bPoint.containsKey('id')) ? _bPoint['id'] as int : null;
    info('создана: id=$testPointId, name=$ptName, city_id=$cityId, partner_id=$partnerId');
  }
  {
    final (s, _) = await req('POST', '/points', body: {
      'name': 'БезЧасов',
      'address': 'ул. Тестовая, 1',
      'city_id': cityId,
      'partner_id': partnerId,
      'latitude': 55.75,
      'longitude': 37.62,
      // отсутствуют opening_hours / closing_hours
    }, token: aT);
    check('POST /points — без часов работы → 4xx', s >= 400);
  }
  {
    final (s, _) = await req('POST', '/points', body: {
      'name': 'НеверноеВремя',
      'address': 'ул. Тестовая, 1',
      'city_id': cityId,
      'partner_id': partnerId,
      'latitude': 55.75,
      'longitude': 37.62,
      'opening_hours': '9am',  // неверный формат
      'closing_hours': '10pm',
    }, token: aT);
    check('POST /points — неверный формат времени → 4xx', s >= 400);
  }
  if (testPointId != null) {
    final (s, b) = await req('GET', '/points/$testPointId', token: aT);
    expectStatus('GET /points/$testPointId — получение', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}, address=${((b as Map?)?["address"] ?? "?")}');

    final updName = 'Обновлено$ts';
    final (s2, b2) = await req('PUT', '/points/$testPointId', body: {
      'name': updName,
      'address': 'ул. Обновлённая, 1',
      'city_id': cityId,
      'partner_id': partnerId,
      'latitude': 55.76,
      'longitude': 37.63,
      'opening_hours': '10:00',
      'closing_hours': '21:00',
    }, token: aT);
    expectStatus('PUT /points/$testPointId — обновление', s2, 200);
    info('новое name=${((b2 as Map?)?["name"] ?? updName)}');

    final (s3, b3) = await req('GET', '/points/$testPointId/categories', token: aT);
    expectStatus('GET /points/$testPointId/categories — категории точки', s3, 200);
    info('категорий у точки: ${(b3 as List?)?.length ?? 0}');

    final (s4, b4) = await req('GET', '/points/$testPointId/reviews', token: aT);
    expectStatus('GET /points/$testPointId/reviews — отзывы точки', s4, 200);
    info('отзывов у точки: ${(b4 as List?)?.length ?? 0}');

    // Добавление отзыва через вложенный маршрут
    {
      final (sr, br) = await req('POST', '/points/$testPointId/reviews',
          body: {'rating': 4.5, 'comment': 'Отличная тестовая точка'}, token: aT);
      expectOk('POST /points/$testPointId/reviews — добавление отзыва', sr);
      final _brMap = br as Map?;
      testPointReviewId = (_brMap != null && _brMap.containsKey('id')) ? _brMap['id'] as int : null;
      info('создан отзыв: id=$testPointReviewId, rating=4.5');
    }
    {
      final (sr, _) = await req('POST', '/points/$testPointId/reviews',
          body: {'rating': 10.0}, token: aT);
      check('POST /points/$testPointId/reviews — рейтинг > 5 → 4xx', sr >= 400);
    }
    {
      final (sr, _) = await req('POST', '/points/$testPointId/reviews',
          body: {}, token: aT);
      check('POST /points/$testPointId/reviews — без рейтинга → 4xx', sr >= 400);
    }
  }
  {
    final (s, _) = await req('GET', '/points/999999', token: aT);
    expectStatus('GET /points/999999 — не найден → 404', s, 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. ПРОДУКТЫ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Продукты');

  int? testProductId;
  final pointForProducts = testPointId ?? 2;
  {
    final (s, b) = await req('GET', '/products', token: aT);
    expectStatus('GET /products — список продуктов', s, 200);
    info('продуктов в базе: ${(b as List?)?.length ?? 0}');
  }
  {
    final prodName = 'ТестПродукт$ts';
    final (s, b) = await req('POST', '/products', body: {
      'name': prodName,
      'description': 'Тестовый продукт',
      'price': 299.0,
      'point_id': pointForProducts,
      'partner_id': partnerId,
    }, token: aT);
    check('POST /products — создание продукта', s == 200 || s == 201);
    final _bProduct = b as Map?;
    testProductId = (_bProduct != null && _bProduct.containsKey('id')) ? _bProduct['id'] as int : null;
    info('создан: id=$testProductId, name=$prodName, price=299.0, point_id=$pointForProducts');
  }
  {
    final (s, b) = await req('POST', '/products', body: {
      'description': 'Без названия и цены',
      'point_id': pointForProducts,
      'partner_id': partnerId,
    }, token: aT);
    check('POST /products — без name и price → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/products', body: {
      'name': 'Плохая',
      'price': -10.0,  // отрицательная цена
      'point_id': pointForProducts,
      'partner_id': partnerId,
    }, token: aT);
    check('POST /products — отрицательная цена → 4xx', s >= 400);
  }
  if (testProductId != null) {
    final (s, b) = await req('GET', '/products/$testProductId', token: aT);
    expectStatus('GET /products/$testProductId — получение', s, 200);
    info('name=${((b as Map?)?["name"] ?? "?")}, price=${((b as Map?)?["price"] ?? "?")}');

    final (s2, b2) = await req('PUT', '/products/$testProductId',
        body: {'name': 'Обновлено$ts', 'price': 349.0}, token: aT);
    expectStatus('PUT /products/$testProductId — обновление', s2, 200);
    info('новая цена: ${((b2 as Map?)?["price"] ?? 349.0)}');
  }
  {
    final (s, _) = await req('GET', '/products/999999', token: aT);
    expectStatus('GET /products/999999 — не найден → 404', s, 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. ОТЗЫВЫ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Отзывы');

  int? testReviewId;
  final reviewPointId = testPointId ?? 2;
  {
    final (s, b) = await req('GET', '/reviews', token: aT);
    expectStatus('GET /reviews — мои отзывы', s, 200);
    info('отзывов: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('POST', '/reviews',
        body: {'point_id': reviewPointId, 'rating': 4.0, 'comment': 'Тестовый отзыв'},
        token: aT);
    expectOk('POST /reviews — создание отзыва', s);
    final _bReview = b as Map?;
    testReviewId = (_bReview != null && _bReview.containsKey('id')) ? _bReview['id'] as int : null;
    info('создан: id=$testReviewId, point_id=$reviewPointId, rating=4.0');
  }
  {
    final (s, b) = await req('POST', '/reviews',
        body: {'point_id': reviewPointId, 'rating': 6.0}, token: aT);
    check('POST /reviews — рейтинг 6 > 5 → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/reviews',
        body: {'point_id': reviewPointId}, token: aT);
    check('POST /reviews — без рейтинга → 4xx', s >= 400);
  }
  {
    final (s, b) = await req('GET', '/reviews/point/$reviewPointId', token: aT);
    expectStatus('GET /reviews/point/$reviewPointId — отзывы точки', s, 200);
    info('отзывов у точки $reviewPointId: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/reviews/user/2', token: aT);
    expectStatus('GET /reviews/user/2 — отзывы пользователя', s, 200);
    info('отзывов у пользователя 2: ${(b as List?)?.length ?? 0}');
  }
  if (testReviewId != null) {
    final (s, b) = await req('GET', '/reviews/$testReviewId', token: aT);
    expectStatus('GET /reviews/$testReviewId — получение отзыва', s, 200);
    info('rating=${((b as Map?)?["rating"] ?? "?")}, comment=${((b as Map?)?["comment"] ?? "?")}');

    final (s2, b2) = await req('PUT', '/reviews/$testReviewId',
        body: {'rating': 3.0, 'comment': 'Обновлённый отзыв'}, token: aT);
    expectStatus('PUT /reviews/$testReviewId — обновление', s2, 200);
    info('новый rating=${((b2 as Map?)?["rating"] ?? 3.0)}');

    final (s3, b3) = await req('PUT', '/reviews/$testReviewId',
        body: {'rating': -1.0}, token: aT);
    check('PUT /reviews/$testReviewId — отрицательный рейтинг → 4xx', s3 >= 400);
    info('ошибка: ${((b3 as Map?)?["error"] ?? (b3 as Map?)?["message"] ?? "?")}');

    final (s4, b4) = await req('DELETE', '/reviews/$testReviewId', token: aT);
    expectStatus('DELETE /reviews/$testReviewId — удаление отзыва', s4, 200);
    info('${((b4 as Map?)?["message"] ?? "удалён")}');

    final (s5, _) = await req('GET', '/reviews/$testReviewId', token: aT);
    expectStatus('GET /reviews/$testReviewId — после удаления → 404', s5, 404);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. ЗАКАЗЫ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Заказы');

  {
    final (s, b) = await req('GET', '/orders', token: aT);
    expectStatus('GET /orders — все заказы', s, 200);
    info('заказов: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/orders/user/2', token: aT);
    expectStatus('GET /orders/user/2 — заказы пользователя 2', s, 200);
    info('заказов у пользователя 2: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 13. ИЗБРАННОЕ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Избранное');

  {
    final (s, b) = await req('GET', '/favorites', token: aT);
    expectStatus('GET /favorites — список избранного', s, 200);
    info('в избранном: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 14. ПРОМОКОДЫ (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Промокоды');

  {
    final (s, b) = await req('GET', '/promo-codes', token: aT);
    expectStatus('GET /promo-codes — все промокоды', s, 200);
    info('промокодов: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/promo-codes/active', token: aT);
    expectStatus('GET /promo-codes/active — активные', s, 200);
    info('активных: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/promo-codes/999999', token: aT);
    check('GET /promo-codes/999999 — не найден → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 15. ИЗМЕНЕНИЯ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Изменения');

  {
    final (s, b) = await req('GET', '/changes', token: aT);
    expectStatus('GET /changes — все изменения', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/changes/recent', token: aT);
    expectStatus('GET /changes/recent — последние изменения', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/changes/user/2', token: aT);
    expectStatus('GET /changes/user/2 — изменения пользователя 2', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 16. УВЕДОМЛЕНИЯ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Уведомления');

  {
    final (s, b) = await req('GET', '/notifications', token: aT);
    expectStatus('GET /notifications — мои уведомления', s, 200);
    info('уведомлений: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/notifications/recent', token: aT);
    expectStatus('GET /notifications/recent — последние', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 17. ИСТОРИЯ ЗАКАЗОВ
  // ═══════════════════════════════════════════════════════════════════════════
  section('История заказов');

  {
    final (s, b) = await req('GET', '/order-history', token: aT);
    expectStatus('GET /order-history — моя история', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-history/user?userId=2', token: aT);
    expectStatus('GET /order-history/user?userId=2 — история пользователя', s, 200);
    info('записей для userId=2: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-history/point?pointId=$reviewPointId', token: aT);
    expectStatus('GET /order-history/point?pointId=$reviewPointId', s, 200);
    info('записей для pointId=$reviewPointId: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-history/by-status?status=pending', token: aT);
    expectStatus('GET /order-history/by-status?status=pending', s, 200);
    info('заказов со статусом pending: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET',
        '/order-history/by-dates?startDate=2024-01-01&endDate=2026-12-31', token: aT);
    expectStatus('GET /order-history/by-dates — диапазон дат', s, 200);
    info('записей за 2024–2026: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('POST', '/order-history', body: {}, token: aT);
    expectStatus('POST /order-history — пустое тело → 400', s, 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/order-history', body: {
      'orderId': 1,
      'pointId': reviewPointId,
      'userId': 2,
      // отсутствует orderDate
    }, token: aT);
    check('POST /order-history — без orderDate → 4xx', s >= 400);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 18. ДЕЙСТВИЯ С ЗАКАЗАМИ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Действия с заказами');

  {
    final (s, b) = await req('GET', '/order-actions', token: aT);
    expectStatus('GET /order-actions — активные действия', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-actions/active', token: aT);
    expectStatus('GET /order-actions/active', s, 200);
    info('активных: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-actions/by-order?orderId=1', token: aT);
    expectStatus('GET /order-actions/by-order?orderId=1', s, 200);
    info('действий по заказу 1: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/order-actions/by-partner?partnerId=$partnerId', token: aT);
    expectStatus('GET /order-actions/by-partner?partnerId=$partnerId', s, 200);
    info('действий партнёра $partnerId: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('POST', '/order-actions', body: {}, token: aT);
    expectStatus('POST /order-actions — пустое тело → 400', s, 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }
  {
    final (s, _) = await req('POST', '/order-actions', body: {
      'orderId': 1,
      // отсутствуют partnerId, actionDescription
    }, token: aT);
    check('POST /order-actions — без обязательных полей → 4xx', s >= 400);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 19. ПЛАТЁЖНЫЕ ТРАНЗАКЦИИ
  // ═══════════════════════════════════════════════════════════════════════════
  section('Платёжные транзакции');

  {
    final (s, b) = await req('GET', '/payment-transactions', token: aT);
    expectStatus('GET /payment-transactions — мои транзакции', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/payment-transactions/user?user_id=2', token: aT);
    expectStatus('GET /payment-transactions/user?user_id=2', s, 200);
    info('транзакций пользователя 2: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/payment-transactions/order?order_id=1', token: aT);
    expectStatus('GET /payment-transactions/order?order_id=1', s, 200);
    info('транзакций по заказу 1: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/payment-transactions/status?status=pending', token: aT);
    expectStatus('GET /payment-transactions/status?status=pending', s, 200);
    info('транзакций со статусом pending: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/payment-transactions/payment-method?payment_method=card', token: aT);
    expectStatus('GET /payment-transactions/payment-method?payment_method=card', s, 200);
    info('транзакций картой: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET',
        '/payment-transactions/date-range?start_date=2024-01-01&end_date=2026-12-31', token: aT);
    expectStatus('GET /payment-transactions/date-range — диапазон дат', s, 200);
    info('записей за 2024–2026: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/payment-transactions/user', token: aT);
    check('GET /payment-transactions/user — без user_id → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 20. СТАТИСТИКА ПАРТНЁРОВ (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Статистика партнёров');

  {
    final (s, b) = await req('GET', '/partner-statistics', token: aT);
    expectStatus('GET /partner-statistics — вся статистика', s, 200);
    final cnt = b is List ? b.length : (b is Map ? b.length : 0);
    info('записей: $cnt');
  }
  {
    final (s, _) = await req('GET',
        '/partner-statistics/by-partner?partner_id=$partnerId', token: aT);
    check('GET /partner-statistics/by-partner?partner_id=$partnerId — 200 или 404',
        s == 200 || s == 404);
    info('HTTP $s (нет статистики — это нормально)');
  }
  {
    final (s, b) = await req('GET', '/partner-statistics/by-partner', token: aT);
    check('GET /partner-statistics/by-partner — без partner_id → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 21. ЛОГИ ДЕЙСТВИЙ (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Логи действий');

  {
    final (s, b) = await req('GET', '/action-logs', token: aT);
    expectStatus('GET /action-logs — все логи', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/action-logs/recent', token: aT);
    expectStatus('GET /action-logs/recent — последние', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/action-logs/user?userId=2', token: aT);
    expectStatus('GET /action-logs/user?userId=2 — логи пользователя', s, 200);
    info('логов пользователя 2: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/action-logs/user', token: aT);
    check('GET /action-logs/user — без userId → 4xx', s >= 400);
    info('ошибка: ${((b as Map?)?["error"] ?? (b as Map?)?["message"] ?? "?")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 22. ЛОГИ ОШИБОК (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Логи ошибок');

  {
    final (s, b) = await req('GET', '/error-logs', token: aT);
    expectStatus('GET /error-logs — все ошибки', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/error-logs/recent', token: aT);
    expectStatus('GET /error-logs/recent — последние', s, 200);
    info('записей: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/error-logs/unresolved', token: aT);
    expectStatus('GET /error-logs/unresolved — нерешённые', s, 200);
    info('нерешённых: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/error-logs/severity?severity=high', token: aT);
    expectStatus('GET /error-logs/severity?severity=high — по серьёзности', s, 200);
    info('с уровнем high: ${(b as List?)?.length ?? 0}');
  }
  {
    final (s, b) = await req('GET', '/error-logs/module?module=auth', token: aT);
    expectStatus('GET /error-logs/module?module=auth — по модулю', s, 200);
    info('по модулю auth: ${(b as List?)?.length ?? 0}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 23. КЕШ (admin)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Кеш');

  {
    final (s, b) = await req('GET', '/cache', token: aT);
    expectStatus('GET /cache — статистика кеша', s, 200);
    final m = b as Map?;
    info('keys=${m?["total_keys"] ?? m?["keys"] ?? "?"}');
  }
  {
    final (s, b) = await req('GET', '/cache/stats', token: aT);
    expectStatus('GET /cache/stats', s, 200);
    info('${(b as Map?)?.keys.take(3).join(", ")}...');
  }
  final cacheKey = 'test_key_$ts';
  {
    final (s, _) = await req('POST', '/cache/set',
        body: {'key': cacheKey, 'value': 'hello', 'ttl': 60}, token: aT);
    expectStatus('POST /cache/set — запись значения', s, 200);
    info('key=$cacheKey, value=hello, ttl=60с');
  }
  {
    final (s, b) = await req('GET', '/cache/get/$cacheKey', token: aT);
    expectStatus('GET /cache/get/$cacheKey — чтение', s, 200);
    final m = b as Map?;
    check('GET /cache/get — exists=true', m?.containsKey('exists') == true);
    info('exists=${m?["exists"]}, value=${m?["value"]}');
  }
  {
    final (s, b) = await req('GET', '/cache/exists/$cacheKey', token: aT);
    expectStatus('GET /cache/exists/$cacheKey — проверка наличия', s, 200);
    info('exists=${((b as Map?)?["exists"] ?? "?")}');
  }
  {
    final (s, b) = await req('GET', '/cache/ttl/$cacheKey', token: aT);
    expectStatus('GET /cache/ttl/$cacheKey — время жизни', s, 200);
    info('ttl=${((b as Map?)?["ttl"] ?? "?")}с');
  }
  {
    final (s, b) = await req('DELETE', '/cache/delete/$cacheKey', token: aT);
    expectStatus('DELETE /cache/delete/$cacheKey — удаление ключа', s, 200);
    info('${((b as Map?)?["message"] ?? "удалён")}');
  }
  {
    final (s, b) = await req('GET', '/cache/tokens/stats', token: aT);
    expectStatus('GET /cache/tokens/stats — статистика токенов', s, 200);
    info('${(b as Map?)?.keys.take(3).join(", ")}...');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 24. ОЧИСТКА — удаление тестовых данных
  // ═══════════════════════════════════════════════════════════════════════════
  section('Очистка тестовых данных');

  if (testPcatId != null) {
    final (s, b) = await req('DELETE', '/point-categories/$testPcatId', token: aT);
    expectStatus('DELETE /point-categories/$testPcatId', s, 200);
    info('${((b as Map?)?["message"] ?? "удалена")}');
  }
  if (testProdcatId != null) {
    final (s, b) = await req('DELETE', '/product-categories/$testProdcatId', token: aT);
    expectStatus('DELETE /product-categories/$testProdcatId', s, 200);
    info('${((b as Map?)?["message"] ?? "удалена")}');
  }
  if (testProductId != null) {
    final (s, b) = await req('DELETE', '/products/$testProductId', token: aT);
    expectStatus('DELETE /products/$testProductId', s, 200);
    info('${((b as Map?)?["message"] ?? "удалён")}');
  }
  if (testPointReviewId != null) {
    await req('DELETE', '/reviews/$testPointReviewId', token: aT);
    info('удалён отзыв точки id=$testPointReviewId');
  }
  if (testPointId != null) {
    final (s, b) = await req('DELETE', '/points/$testPointId', token: aT);
    expectStatus('DELETE /points/$testPointId', s, 200);
    info('${((b as Map?)?["message"] ?? "удалена")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 25. ОБНОВЛЕНИЕ ТОКЕНА (в конце — ротирует сессию)
  // ═══════════════════════════════════════════════════════════════════════════
  section('Обновление токена (refresh)');

  {
    final (_, freshLogin) = await req('POST', '/login',
        body: {'username': 'adminuser', 'password': 'Admin@1234'});
    final _freshLoginMap = freshLogin as Map?;
    final refreshToken = (_freshLoginMap != null && _freshLoginMap.containsKey('refresh_token'))
        ? _freshLoginMap['refresh_token'] as String
        : null;
    if (refreshToken != null) {
      info('получен refresh_token (${refreshToken.substring(0, 20)}...)');
      final (s, b) = await req('POST', '/auth/refresh',
          body: {'refresh_token': refreshToken});
      expectStatus('POST /auth/refresh — корректный токен → 200', s, 200);
      final hasToken = (b as Map?)?.containsKey('access_token') == true;
      check('POST /auth/refresh → новый access_token в ответе', hasToken);
      if (hasToken) info('новый access_token получен');
    } else {
      check('POST /auth/refresh → refresh_token из /login', false);
    }
    final (s2, b2) = await req('POST', '/auth/refresh',
        body: {'refresh_token': 'невалидный.токен.здесь'});
    check('POST /auth/refresh — недействительный токен → 4xx', s2 >= 400);
    info('ошибка: ${((b2 as Map?)?["error"] ?? (b2 as Map?)?["message"] ?? "?")}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ИТОГ
  // ═══════════════════════════════════════════════════════════════════════════
  _printSummary();
}

void _printSummary() {
  final total = _pass + _fail;
  print('\n$_bold${_cyan}═══════════════════════════════════════════$_reset');
  if (_fail == 0) {
    print('$_bold${_green}  ПРОЙДЕНО $_pass / $total тестов$_reset');
  } else {
    print('$_bold${_red}  ПРОЙДЕНО $_pass / $total  |  ПРОВАЛЕНО $_fail$_reset');
  }
  print('$_bold${_cyan}═══════════════════════════════════════════$_reset');

  if (_failures.isNotEmpty) {
    print('\n${_red}Провалившиеся тесты:$_reset');
    for (final f in _failures) {
      print('  ${_red}✗$_reset $f');
    }
  }
  print('');

  if (_fail > 0) exit(1);
}