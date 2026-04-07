import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/CacheService.dart';
import '../utils/AuthUtilsWithCache.dart' as AuthCache;
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';

class CacheController {
  final CacheService _cacheService;

  late final Router _router;

  CacheController(this._cacheService) {
    _router = Router();
    _router.get('/', _getCacheStats);
    _router.get('/stats', _getCacheStats);
    _router.delete('/clear', _clearCache);
    _router.delete('/clear/<pattern>', _clearCacheByPattern);
    _router.get('/get/<key>', _getValue);
    _router.post('/set', _setValue);
    _router.delete('/delete/<key>', _deleteValue);
    _router.get('/exists/<key>', _existsKey);
    _router.get('/ttl/<key>', _getTTL);
    _router.post('/expire/<key>', _setTTL);
    _router.get('/tokens/stats', _getTokenStats);
    _router.post('/tokens/invalidate', _invalidateToken);
    _router.post('/tokens/invalidate-user', _invalidateUserTokens);
    _router.post('/tokens/cleanup', _cleanupExpiredTokens);
  }

  Router get router => _router;

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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _clearCache(Request request) async {
    try {
      final success = await _cacheService.flushAll();
      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'Кеш успешно очищен' : 'Ошибка очистки кеша',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _clearCacheByPattern(Request request, String pattern) async {
    try {
      final count = await _cacheService.deleteByPattern(pattern);
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'РЈРґР°Р»РµРЅРѕ $count РєР»СЋС‡РµР№ РїРѕ РїР°С‚С‚РµСЂРЅСѓ $pattern',
          'count': count,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
          'message': success ? 'Значение успешно сохранено' : 'Ошибка установки значения',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
          'message': ttl == -1 ? 'Ключ не имеет TTL или не существует' : 'TTL в секундах',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
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
          'message': 'Р’СЃРµ С‚РѕРєРµРЅС‹ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РёРЅРІР°Р»РёРґРёСЂРѕРІР°РЅС‹',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _cleanupExpiredTokens(Request request) async {
    try {
      await AuthCache.AuthUtils.cleanupExpiredTokens();

      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Истёкшие токены успешно удалены',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: {'Content-Type': 'application/json'});
    }
  }
}
