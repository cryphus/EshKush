import 'package:shelf/shelf.dart';
import '../utils/AuthUtils.dart';
import 'dart:async';

class SecurityMiddleware {
  static final Map<String, List<DateTime>> _requests = {};
  static const int maxRequests = 100;
  static const Duration window = Duration(minutes: 1);

  static Middleware securityHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
          'Content-Security-Policy': "default-src 'self'",
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
        });
      };
    };
  }

  static Middleware rateLimiter() {
    return (Handler innerHandler) {
      return (Request request) async {
        final ip = request.headers['x-forwarded-for'] ?? 'unknown';
        if (!_isAllowed(ip)) {
          return Response(429, body: 'Too many requests');
        }
        return innerHandler(request);
      };
    };
  }

  static Middleware checkJWT() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return innerHandler(request);
        }

        final token = request.headers['authorization']?.replaceAll('Bearer ', '');
        if (token == null) {
          return Response.unauthorized('Требуется авторизация');
        }

        try {
          final payload = AuthUtils.verifyToken(token);
          final modifiedRequest = request.change(context: {
            'user': payload,
          });
          return innerHandler(modifiedRequest);
        } catch (e) {
          return Response.unauthorized('Недействительный токен');
        }
      };
    };
  }

  static bool _isAllowed(String ip) {
    final now = DateTime.now();
    _requests[ip] = _requests[ip]?.where(
      (time) => now.difference(time) < window
    ).toList() ?? [];
    
    final requestCount = _requests[ip]?.length ?? 0;
    if (requestCount >= maxRequests) {
      return false;
    }
    
    _requests[ip]?.add(now);
    return true;
  }
} 