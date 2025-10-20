import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/CacheService.dart';
import '../utils/AuthUtilsWithCache.dart' as AuthCache;

class CacheController {
  final CacheService _cacheService;

  CacheController(this._cacheService);

  Router get router {
    final router = Router();

    router.get('/stats', _getCacheStats);
    
    router.delete('/clear', _clearCache);
    
    router.delete('/clear/<pattern>', _clearCacheByPattern);
    
    router.get('/get/<key>', _getValue);
    
    router.post('/set', _setValue);
    
    router.delete('/delete/<key>', _deleteValue);
    
    router.get('/exists/<key>', _existsKey);
    
    router.get('/ttl/<key>', _getTTL);
    
    router.post('/expire/<key>', _setTTL);
    
    router.get('/tokens/stats', _getTokenStats);
    
    router.post('/tokens/invalidate', _invalidateToken);
    
    router.post('/tokens/invalidate-user', _invalidateUserTokens);
    
    router.post('/tokens/cleanup', _cleanupExpiredTokens);

    return router;
  }

  Future<Response> _getCacheStats(Request request) async {
    try {
      final stats = await _cacheService.getStats();
      return Response.ok(
        jsonEncode({
          'success': true,
          'data': stats,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка получения статистики кеша: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _clearCache(Request request) async {
    try {
      final success = await _cacheService.flushAll();
      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'Кеш очищен' : 'Ошибка очистки кеша',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка очистки кеша: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _clearCacheByPattern(Request request, String pattern) async {
    try {
      final count = await _cacheService.deleteByPattern(pattern);
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Удалено $count ключей по паттерну $pattern',
          'count': count,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка очистки кеша по паттерну: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getValue(Request request, String key) async {
    try {
      final value = await _cacheService.get(key);
      return Response.ok(
        jsonEncode({
          'success': true,
          'key': key,
          'value': value,
          'exists': value != null,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка получения значения: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _setValue(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final key = data['key'] as String;
      final value = data['value'];
      final ttlSeconds = data['ttl'] as int?;

      final ttl = ttlSeconds != null ? Duration(seconds: ttlSeconds) : null;
      final success = await _cacheService.set(key, value, ttl: ttl);

      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'Значение установлено' : 'Ошибка установки значения',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка установки значения: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteValue(Request request, String key) async {
    try {
      final success = await _cacheService.delete(key);
      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'Значение удалено' : 'Ключ не найден',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка удаления значения: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _existsKey(Request request, String key) async {
    try {
      final exists = await _cacheService.exists(key);
      return Response.ok(
        jsonEncode({
          'success': true,
          'key': key,
          'exists': exists,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка проверки существования ключа: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTTL(Request request, String key) async {
    try {
      final ttl = await _cacheService.ttl(key);
      return Response.ok(
        jsonEncode({
          'success': true,
          'key': key,
          'ttl': ttl,
          'message': ttl == -1 ? 'Ключ не существует или не имеет TTL' : 'TTL в секундах',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка получения TTL: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _setTTL(Request request, String key) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final ttlSeconds = data['ttl'] as int;

      final success = await _cacheService.expire(key, Duration(seconds: ttlSeconds));

      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'TTL установлен' : 'Ключ не найден',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка установки TTL: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTokenStats(Request request) async {
    try {
      final stats = await AuthCache.AuthUtils.getTokenStats();
      return Response.ok(
        jsonEncode({
          'success': true,
          'data': stats,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка получения статистики токенов: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _invalidateToken(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final token = data['token'] as String;
      final isRefreshToken = data['isRefreshToken'] as bool? ?? false;

      await AuthCache.AuthUtils.invalidateToken(token, isRefreshToken: isRefreshToken);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Токен инвалидирован',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка инвалидации токена: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _invalidateUserTokens(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final userId = data['userId'] as int;

      await AuthCache.AuthUtils.invalidateUserTokens(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Все токены пользователя инвалидированы',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка инвалидации токенов пользователя: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _cleanupExpiredTokens(Request request) async {
    try {
      await AuthCache.AuthUtils.cleanupExpiredTokens();

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Истекшие токены очищены',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Ошибка очистки истекших токенов: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
