import 'package:shelf/shelf.dart';
import '../utils/AuthUtils.dart';
import '../repositories/UserSessionRepository.dart';

class SecurityMiddleware {
  static final Map<String, List<DateTime>> _requests = {};
  static const int maxRequests = 100;
  static const Duration window = Duration(minutes: 1);

  static Middleware securityHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          // Оставить
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY', // или SAMEORIGIN по требованиям
          // Добавить
          'Content-Security-Policy':
              "default-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Permissions-Policy': 'accelerometer=(), camera=(), geolocation=(), microphone=(), payment=(), usb=()',
          'Cross-Origin-Opener-Policy': 'same-origin',
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

  static Middleware checkJWT(UserSessionRepository sessionRepository, {List<String> openPaths = const []}) {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('');
        }

        final path = request.url.path;
        if (path.isEmpty || openPaths.any((p) => path.startsWith(p))) {
          return innerHandler(request);
        }

        final token = request.headers['authorization']?.replaceAll('Bearer ', '');
        if (token == null) {
          return Response.unauthorized('Требуется авторизация');
        }

        try {
          final payload = AuthUtils.verifyToken(token);
          final userId = payload['id'] as int;
          final refreshJti = payload['rtj']?.toString() ?? '';
          if (refreshJti.isEmpty) {
            return Response.unauthorized('Токен без refresh jti');
          }

          final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
          final session = await sessionRepository.findActiveByRefreshJtiHash(refreshJtiHash);
          if (session == null || session.userId != userId) {
            return Response.unauthorized('Сессия недействительна');
          }

          sessionRepository.updateLastActive(session.id);

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