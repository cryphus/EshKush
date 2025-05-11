import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../utils/AuthUtils.dart';

class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, List<DateTime>> _requests = {};

  RateLimiter(this.maxRequests, this.window);

  bool checkLimit(String key) {
    final now = DateTime.now();
    _requests[key] = _requests[key]?.where((time) => now.difference(time) <= window).toList() ?? [];
    
    if (_requests[key]!.length >= maxRequests) {
      return false;
    }
    
    _requests[key]!.add(now);
    return true;
  }
}

class SecurityMiddleware {
  final RateLimiter _rateLimiter;
  final List<String> _allowedOrigins;
  final List<String> _allowedMethods;
  final List<String> _allowedHeaders;

  SecurityMiddleware({
    int maxRequests = 100,
    Duration window = const Duration(minutes: 1),
    List<String>? allowedOrigins,
    List<String>? allowedMethods,
    List<String>? allowedHeaders,
  }) : 
    _rateLimiter = RateLimiter(maxRequests, window),
    _allowedOrigins = allowedOrigins ?? ['http://localhost:3000'],
    _allowedMethods = allowedMethods ?? ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    _allowedHeaders = allowedHeaders ?? [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With'
    ];

  Middleware get middleware => createMiddleware(
    requestHandler: _handleRequest,
    responseHandler: (response) => response.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': _allowedMethods.join(', '),
      'Access-Control-Allow-Headers': _allowedHeaders.join(', '),
    }),
  );

  Future<Response?> _handleRequest(Request request) async {
    if (request.method == 'OPTIONS') {
      return _handleCors(request);
    }

    final clientIp = request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'];
    if (clientIp != null && !_rateLimiter.checkLimit(clientIp)) {
      return Response(429, 
        body: jsonEncode({'error': 'Слишком много запросов. Попробуйте позже.'}),
        headers: _getCorsHeaders(request),
      );
    }

    // Проверка авторизации для защищенных маршрутов
    if (_isProtectedRoute(request.url.path)) {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(request),
        );
      }

      try {
        final payload = AuthUtils.verifyToken(token);
        if (_isTokenExpired(payload)) {
          return Response(401, 
            body: jsonEncode({'error': 'Токен истек'}),
            headers: _getCorsHeaders(request),
          );
        }
      } catch (e) {
        return Response(401, 
          body: jsonEncode({'error': 'Недействительный токен'}),
          headers: _getCorsHeaders(request),
        );
      }
    }

    return null;
  }

  Response _handleResponse(Response response, Request request) {
    return response.change(headers: _getCorsHeaders(request));
  }

  Response _handleCors(Request request) {
    final origin = request.headers['origin'];
    if (origin != null && _allowedOrigins.contains(origin)) {
      return Response.ok('', headers: {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': _allowedMethods.join(', '),
        'Access-Control-Allow-Headers': _allowedHeaders.join(', '),
        'Access-Control-Max-Age': '86400',
      });
    }
    return Response(403, body: jsonEncode({'error': 'CORS не разрешен'}));
  }

  Map<String, String> _getCorsHeaders(Request request) {
    final origin = request.headers['origin'];
    if (origin != null && _allowedOrigins.contains(origin)) {
      return {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': _allowedMethods.join(', '),
        'Access-Control-Allow-Headers': _allowedHeaders.join(', '),
      };
    }
    return {};
  }

  bool _isProtectedRoute(String path) {
    // Список путей, не требующих авторизации
    final publicPaths = [
      '/auth/login',
      '/auth/register',
      '/health',
    ];
    return !publicPaths.contains(path);
  }

  bool _isTokenExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now());
  }
} 