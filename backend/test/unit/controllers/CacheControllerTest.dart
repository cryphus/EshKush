import 'dart:convert';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/controllers/CacheController.dart';
import 'package:backend/services/CacheService.dart';

import 'CacheControllerTest.mocks.dart';

@GenerateMocks([CacheService])
void main() {
  late MockCacheService cacheService;
  late Handler handler;

  setUpAll(() => AppConfig.initForTesting());

  setUp(() {
    cacheService = MockCacheService();
    handler = CacheController(cacheService).router.call;
  });

  Request _get(String path) =>
      Request('GET', Uri.parse('http://localhost/$path'));

  Request _post(String path, Map<String, dynamic> body) =>
      Request('POST', Uri.parse('http://localhost/$path'),
          body: jsonEncode(body),
          headers: {'content-type': 'application/json'});

  Request _delete(String path) =>
      Request('DELETE', Uri.parse('http://localhost/$path'));

  // ── GET /stats ────────────────────────────────────────────────────────────
  group('GET /stats', () {
    test('200 возвращает статистику кеша', () async {
      when(cacheService.getStats()).thenAnswer((_) async => {'keys': 0, 'hits': 0});
      final resp = await handler(_get('stats'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['success'], true);
    });
  });

  // ── DELETE /clear ─────────────────────────────────────────────────────────
  group('DELETE /clear', () {
    test('200 очищает кеш', () async {
      when(cacheService.flushAll()).thenAnswer((_) async => true);
      final resp = await handler(_delete('clear'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['success'], true);
    });
  });

  // ── DELETE /clear/<pattern> ───────────────────────────────────────────────
  group('DELETE /clear/<pattern>', () {
    test('200 удаляет ключи по паттерну', () async {
      when(cacheService.deleteByPattern('user:*')).thenAnswer((_) async => 5);
      final resp = await handler(_delete('clear/user:*'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['count'], 5);
    });
  });

  // ── GET /get/<key> ────────────────────────────────────────────────────────
  group('GET /get/<key>', () {
    test('200 возвращает значение (существующий ключ)', () async {
      when(cacheService.get('mykey')).thenAnswer((_) async => 'myvalue');
      final resp = await handler(_get('get/mykey'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['exists'], true);
    });

    test('200 возвращает exists=false для несуществующего ключа', () async {
      when(cacheService.get('nokey')).thenAnswer((_) async => null);
      final resp = await handler(_get('get/nokey'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['exists'], false);
    });
  });

  // ── POST /set ─────────────────────────────────────────────────────────────
  group('POST /set', () {
    test('200 сохраняет значение', () async {
      when(cacheService.set('k', 'v', ttl: anyNamed('ttl')))
          .thenAnswer((_) async => true);
      final resp = await handler(_post('set', {'key': 'k', 'value': 'v'}));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['success'], true);
    });
  });

  // ── DELETE /delete/<key> ──────────────────────────────────────────────────
  group('DELETE /delete/<key>', () {
    test('200 удаляет ключ', () async {
      when(cacheService.delete('k')).thenAnswer((_) async => true);
      final resp = await handler(_delete('delete/k'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['success'], true);
    });
  });

  // ── GET /exists/<key> ─────────────────────────────────────────────────────
  group('GET /exists/<key>', () {
    test('200 проверяет существование ключа', () async {
      when(cacheService.exists('k')).thenAnswer((_) async => true);
      final resp = await handler(_get('exists/k'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['exists'], true);
    });
  });

  // ── GET /ttl/<key> ────────────────────────────────────────────────────────
  group('GET /ttl/<key>', () {
    test('200 возвращает TTL ключа', () async {
      when(cacheService.ttl('k')).thenAnswer((_) async => 3600);
      final resp = await handler(_get('ttl/k'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
      expect(body['ttl'], 3600);
    });
  });
}
