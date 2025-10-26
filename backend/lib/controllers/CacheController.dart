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
          'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РєРµС€Р°: $e',
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
          'message': success ? 'РљРµС€ РѕС‡РёС‰РµРЅ' : 'РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РєРµС€Р°',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РєРµС€Р°: $e',
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
          'message': 'РЈРґР°Р»РµРЅРѕ $count РєР»СЋС‡РµР№ РїРѕ РїР°С‚С‚РµСЂРЅСѓ $pattern',
          'count': count,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РєРµС€Р° РїРѕ РїР°С‚С‚РµСЂРЅСѓ: $e',
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
          'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·РЅР°С‡РµРЅРёСЏ: $e',
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
          'message': success ? 'Р—РЅР°С‡РµРЅРёРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅРѕ' : 'РћС€РёР±РєР° СѓСЃС‚Р°РЅРѕРІРєРё Р·РЅР°С‡РµРЅРёСЏ',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° СѓСЃС‚Р°РЅРѕРІРєРё Р·РЅР°С‡РµРЅРёСЏ: $e',
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
          'message': success ? 'Р—РЅР°С‡РµРЅРёРµ СѓРґР°Р»РµРЅРѕ' : 'РљР»СЋС‡ РЅРµ РЅР°Р№РґРµРЅ',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ Р·РЅР°С‡РµРЅРёСЏ: $e',
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
          'error': 'РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё СЃСѓС‰РµСЃС‚РІРѕРІР°РЅРёСЏ РєР»СЋС‡Р°: $e',
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
          'message': ttl == -1 ? 'РљР»СЋС‡ РЅРµ СЃСѓС‰РµСЃС‚РІСѓРµС‚ РёР»Рё РЅРµ РёРјРµРµС‚ TTL' : 'TTL РІ СЃРµРєСѓРЅРґР°С…',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ TTL: $e',
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
          'message': success ? 'TTL СѓСЃС‚Р°РЅРѕРІР»РµРЅ' : 'РљР»СЋС‡ РЅРµ РЅР°Р№РґРµРЅ',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° СѓСЃС‚Р°РЅРѕРІРєРё TTL: $e',
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
          'error': 'РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё С‚РѕРєРµРЅРѕРІ: $e',
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
          'message': 'РўРѕРєРµРЅ РёРЅРІР°Р»РёРґРёСЂРѕРІР°РЅ',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РёРЅРІР°Р»РёРґР°С†РёРё С‚РѕРєРµРЅР°: $e',
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
          'message': 'Р’СЃРµ С‚РѕРєРµРЅС‹ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РёРЅРІР°Р»РёРґРёСЂРѕРІР°РЅС‹',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РёРЅРІР°Р»РёРґР°С†РёРё С‚РѕРєРµРЅРѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e',
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
          'message': 'РСЃС‚РµРєС€РёРµ С‚РѕРєРµРЅС‹ РѕС‡РёС‰РµРЅС‹',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РёСЃС‚РµРєС€РёС… С‚РѕРєРµРЅРѕРІ: $e',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
