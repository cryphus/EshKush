import 'package:shelf/shelf.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RateLimiterStore.dart';
import '../repositories/UserSessionRepository.dart';

class SecurityMiddleware {

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

  /// Middleware ограничения частоты запросов.
  ///
  /// [store] — хранилище счётчиков. По умолчанию [InMemoryRateLimiterStore].
  ///   Для нескольких инстансов передайте Redis-реализацию [RateLimiterStore].
  /// [maxRequests] — максимум запросов в окне (из AppConfig.rateLimitRequests).
  /// [window] — размер окна (из AppConfig.rateLimitWindow).
  static Middleware rateLimiter({
    RateLimiterStore? store,
    int maxRequests = 100,
    Duration window = const Duration(minutes: 1),
  }) {
    final effectiveStore = store ?? InMemoryRateLimiterStore();
    return (Handler innerHandler) {
      return (Request request) async {
        final ip = request.headers['x-forwarded-for']
            ?? request.headers['x-real-ip']
            ?? 'unknown';
        final count = await effectiveStore.increment(ip, window);
        if (count > maxRequests) {
          return Response(
            429,
            body: '{"error":"Too many requests","retryAfterSeconds":${window.inSeconds}}',
            headers: {
              'Content-Type': 'application/json',
              'Retry-After': '${window.inSeconds}',
              'X-RateLimit-Limit': '$maxRequests',
              'X-RateLimit-Remaining': '0',
            },
          );
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
        if (path.isEmpty || path == '/' || openPaths.any((p) => path.startsWith(p))) {
          return innerHandler(request);
        }

        final token = request.headers['authorization']?.replaceAll('Bearer ', '');
        if (token == null) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Требуется авторизация',
            code: ErrorCode.unauthorized,
            headers: {'Content-Type': 'application/json'},
          );
        }

        try {
          final payload = AuthUtils.verifyToken(token);
          final userId = payload['id'] as int;
          final refreshJti = payload['rtj']?.toString() ?? '';
          if (refreshJti.isEmpty) {
            return ErrorResponseUtils.errorResponseWithMessage(
              'Токен без refresh jti',
              code: ErrorCode.unauthorized,
              headers: {'Content-Type': 'application/json'},
            );
          }

          final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
          final session = await sessionRepository.findActiveByRefreshJtiHash(refreshJtiHash);
          if (session == null || session.userId != userId) {
            return ErrorResponseUtils.errorResponseWithMessage(
              'Сессия недействительна',
              code: ErrorCode.unauthorized,
              headers: {'Content-Type': 'application/json'},
            );
          }

          sessionRepository.updateLastActive(session.id);

          final modifiedRequest = request.change(context: {
            'user': payload,
          });
          return innerHandler(modifiedRequest);
        } catch (e) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Недействительный токен',
            code: ErrorCode.unauthorized,
            headers: {'Content-Type': 'application/json'},
          );
        }
      };
    };
  }

}