import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/HealthController.dart';
import 'package:backend/services/CacheService.dart';

import 'HealthControllerTest.mocks.dart';

@GenerateMocks([PostgreSQLConnection, CacheService, PostgreSQLResult])
void main() {
  late MockPostgreSQLConnection db;
  late MockCacheService cache;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    db    = MockPostgreSQLConnection();
    cache = MockCacheService();
    handler = HealthController(db, cache).router.call;
  });

  Request _get() => Request('GET', Uri.parse('http://localhost/'));

  // ── GET / ─────────────────────────────────────────────────────────────────
  group('GET /', () {
    test('200 ok когда БД и кеш доступны', () async {
      when(db.query(any)).thenAnswer((_) async => MockPostgreSQLResult());
      when(cache.isConnected).thenReturn(true);
      final resp = await handler(_get());
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'ok');
      expect(body['checks']['database'], 'ok');
      expect(body['checks']['cache'], 'ok');
    });

    test('503 error когда БД недоступна', () async {
      when(db.query(any)).thenThrow(Exception('Connection refused'));
      when(cache.isConnected).thenReturn(true);
      final resp = await handler(_get());
      expect(resp.statusCode, 503);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'error');
      expect(body['checks']['database'], 'error');
    });

    test('200 degraded когда кеш недоступен но БД ок', () async {
      when(db.query(any)).thenAnswer((_) async => MockPostgreSQLResult());
      when(cache.isConnected).thenReturn(false);
      final resp = await handler(_get());
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['status'], 'degraded');
      expect(body['checks']['cache'], 'error');
    });

    test('ответ содержит version и uptime', () async {
      when(db.query(any)).thenAnswer((_) async => MockPostgreSQLResult());
      when(cache.isConnected).thenReturn(true);
      final resp = await handler(_get());
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['version'], isNotNull);
      expect(body['uptime'], isA<int>());
    });
  });
}
