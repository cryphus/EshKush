import 'package:shelf/shelf.dart';
import 'dart:io';
import '../config/AppConfig.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../repositories/UserSessionRepository.dart';

class SecurityMiddleware {
  static final Map<String, List<DateTime>> _requests = {};

  // Throttle last_active DB writes: at most once per 5 minutes per session.
  static final Map<int, DateTime> _lastActiveUpdates = {};
  static const Duration _lastActiveThrottle = Duration(minutes: 5);

  /// Подбирает CORS-заголовки для запроса на основе whitelist из AppConfig.
  /// Если origin запроса отсутствует в allowedOrigins — заголовок
  /// Access-Control-Allow-Origin не выставляется (браузер отклонит запрос).
  /// В dev, если allowedOrigins пуст, используем зеркало origin для удобства.
  static Map<String, String> corsHeadersFor(Request request) {
    final config = AppConfig();
    final origin = request.headers['origin'] ?? request.headers['Origin'];
    final allowed = config.allowedOrigins.where((o) => o.isNotEmpty).toList();

    final headers = <String, String>{
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
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

  static Middleware securityHeaders() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'X-XSS-Protection': '1; mode=block',
          'Strict-Transport-Security':
              'max-age=31536000; includeSubDomains; preload',
          'Referrer-Policy': 'strict-origin-when-cross-origin',
          'Content-Security-Policy':
              "default-src 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'none'; img-src 'self' data: https:; upgrade-insecure-requests",
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
              body: '{"error":"Тело запроса превышает лимит","limit":$limit}',
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
  static Middleware rateLimiter({
    int? maxRequests,
    Duration? window,
    List<String> pathPrefixes = const [],
  }) {
    final config = AppConfig();
    final limit = maxRequests ?? config.rateLimitRequests;
    final windowDuration = window ?? config.rateLimitWindow;
    return (Handler innerHandler) {
      return (Request request) async {
        if (pathPrefixes.isNotEmpty &&
            !pathPrefixes.any((prefix) =>
                _matchesPathPrefixSegment(request.url.path, prefix))) {
          return innerHandler(request);
        }

        // For authenticated requests use user_id to prevent IP spoofing
        final userPayload = request.context['user'] as Map<String, dynamic>?;
        final String key;
        if (userPayload != null) {
          key = 'user:${userPayload['id']}';
        } else {
          key = 'ip:${extractClientIp(request)}';
        }
        if (!_isAllowed(key, limit, windowDuration)) {
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

  static String extractClientIp(Request request) {
    final config = AppConfig();
    final remoteIp = _extractRemoteIpFromConnectionInfo(request);
    final canTrustProxyHeaders = config.trustProxyHeaders &&
        (remoteIp == null || config.trustedProxyIps.contains(remoteIp));

    if (canTrustProxyHeaders) {
      final forwarded = request.headers['x-forwarded-for'];
      if (forwarded != null && forwarded.trim().isNotEmpty) {
        return forwarded.split(',').first.trim();
      }

      final realIp = request.headers['x-real-ip'];
      if (realIp != null && realIp.trim().isNotEmpty) {
        return realIp.trim();
      }
    }

    if (remoteIp != null && remoteIp.isNotEmpty) {
      return remoteIp;
    }

    return 'unknown';
  }

  static String? _extractRemoteIpFromConnectionInfo(Request request) {
    final connectionInfo = request.context['shelf.io.connection_info'];
    if (connectionInfo is HttpConnectionInfo) {
      final ip = connectionInfo.remoteAddress.address.trim();
      if (ip.isNotEmpty) return ip;
    }
    return null;
  }

  static bool _matchesPathPrefixSegment(String path, String prefix) {
    if (prefix.isEmpty) return path.isEmpty;
    return path == prefix || path.startsWith('$prefix/');
  }

  static Middleware checkJWT(UserSessionRepository sessionRepository,
      {List<String> openPaths = const []}) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;
        if (path.isEmpty ||
            path == '/' ||
            openPaths.any((p) => _matchesPathPrefixSegment(path, p))) {
          return innerHandler(request);
        }

        final token =
            request.headers['authorization']?.replaceAll('Bearer ', '');
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
          final session = await sessionRepository
              .findActiveByRefreshJtiHash(refreshJtiHash);
          if (session == null || session.userId != userId) {
            return ErrorResponseUtils.errorResponseWithMessage(
              'Сессия недействительна',
              code: ErrorCode.unauthorized,
              headers: {'Content-Type': 'application/json'},
            );
          }

          final lastUpdate = _lastActiveUpdates[session.id];
          if (lastUpdate == null ||
              DateTime.now().difference(lastUpdate) >= _lastActiveThrottle) {
            await sessionRepository.updateLastActive(session.id);
            _lastActiveUpdates[session.id] = DateTime.now();
          }

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
