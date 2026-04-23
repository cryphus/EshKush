import 'package:shelf/shelf.dart';
import '../config/AppConfig.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RateLimiterStore.dart';
import '../repositories/UserSessionRepository.dart';

class SecurityMiddleware {
  static final Map<String, List<DateTime>> _requests = {};

  /// Подбирает CORS-заголовки для запроса на основе whitelist из AppConfig.
  /// Если origin запроса отсутствует в allowedOrigins — заголовок
  /// Access-Control-Allow-Origin не выставляется (браузер отклонит запрос).
  /// В dev, если allowedOrigins пуст, используем зеркало origin для удобства.
  static Map<String, String> corsHeadersFor(Request request) {
    final config = AppConfig();
    final origin = request.headers['origin'] ?? request.headers['Origin'];
    final allowed = config.allowedOrigins.where((o) => o.isNotEmpty).toList();

    final headers = <String, String>{
      'Access-Control-Allow-Methods':
          'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, Content-Type, Accept, Authorization, X-Webhook-Secret',
      'Access-Control-Max-Age': '86400',
      'Vary': 'Origin',
    };

    if (origin != null && allowed.contains(origin)) {
      headers['Access-Control-Allow-Origin'] = origin;
      headers['Access-Control-Allow-Credentials'] = 'true';
    }
    return headers;
  }

  /// CORS middleware: отвечает на preflight и добавляет заголовки на ответы.
  static Middleware corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeadersFor(request));
        }
        final response = await innerHandler(request);
        return response.change(headers: corsHeadersFor(request));
      };
    };
  }

  static Middleware securityHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Content-Security-Policy': "default-src 'self'",
          'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
          'Cross-Origin-Opener-Policy': 'same-origin',
        });
      };
    };
  }

  /// Лимит размера тела запроса. Проверяет Content-Length и отклоняет
  /// запросы больше [maxBytes] с 413 Payload Too Large.
  static Middleware requestSizeLimit({int? maxBytes}) {
    final limit = maxBytes ?? AppConfig().maxRequestBodyBytes;
    return (Handler innerHandler) {
      return (Request request) async {
        final contentLengthHeader = request.headers['content-length'];
        if (contentLengthHeader != null) {
          final len = int.tryParse(contentLengthHeader);
          if (len != null && len > limit) {
            return Response(
              413,
              body:
                  '{"error":"Тело запроса превышает лимит","limit":$limit}',
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return innerHandler(request);
      };
    };
  }

  /// Rate-limiter per IP. Читает `maxRequests` и `window` из AppConfig.
  /// Ожидается точечное применение (e.g. к /auth/* и /login), не глобально.
  static Middleware rateLimiter({int? maxRequests, Duration? window}) {
    final config = AppConfig();
    final limit = maxRequests ?? config.rateLimitRequests;
    final windowDuration = window ?? config.rateLimitWindow;
    return (Handler innerHandler) {
      return (Request request) async {
        final ip = request.headers['x-forwarded-for'] ??
            request.headers['x-real-ip'] ??
            'unknown';
        if (!_isAllowed(ip, limit, windowDuration)) {
          return Response(
            429,
            body: '{"error":"Слишком много запросов, повторите позже"}',
            headers: {
              'content-type': 'application/json',
              'retry-after': '${windowDuration.inSeconds}',
            },
          );
        }
        return innerHandler(request);
      };
    };
  }

  static bool _isAllowed(String ip, int limit, Duration window) {
    final now = DateTime.now();
    final times = _requests[ip] ?? [];
    final filtered = times.where((t) => now.difference(t) < window).toList();
    filtered.add(now);
    _requests[ip] = filtered;
    return filtered.length <= limit;
  }

  static Middleware checkJWT(UserSessionRepository sessionRepository, {List<String> openPaths = const []}) {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeadersFor(request));
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

          await sessionRepository.updateLastActive(session.id);

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