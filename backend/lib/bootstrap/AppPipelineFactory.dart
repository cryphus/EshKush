import 'package:backend/bootstrap/AppRouterFactory.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/config/Routes.dart';
import 'package:backend/middleware/CorsMiddleware.dart';
import 'package:backend/middleware/LoggingMiddleware.dart';
import 'package:backend/middleware/RbacMiddleware.dart';
import 'package:backend/middleware/SecurityMiddleware.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/services/ActionLogService.dart';
import 'package:shelf/shelf.dart';

class AppPipelineFactory {
  static Handler create({
    required Handler appHandler,
    required UserSessionRepository userSessionRepository,
    required ActionLogService actionLogService,
    required CorsMiddleware corsMiddleware,
  }) {
    final openPaths = AppRouterFactory.openPaths;
    final appConfig = AppConfig();
    final authRateLimitRequests = appConfig.rateLimitRequests;
    final authRateLimitWindow = appConfig.rateLimitWindow;

    return Pipeline()
        .addMiddleware(SecurityMiddleware.securityHeaders())
        .addMiddleware(corsMiddleware.call())
        .addMiddleware(SecurityMiddleware.requestSizeLimit())
        .addMiddleware(SecurityMiddleware.rateLimiter(
          maxRequests: authRateLimitRequests,
          window: authRateLimitWindow,
          pathPrefixes: ['login', 'auth/register', 'auth/refresh'],
        ))
        .addMiddleware(_jsonContentType())
        .addMiddleware(SecurityMiddleware.checkJWT(
          userSessionRepository,
          openPaths: openPaths,
        ))
        .addMiddleware(RbacMiddleware.withRoleRules(
          Routes.rbacRoleRules,
          openPathPrefixes: openPaths,
        ))
        .addMiddleware(
          LoggingMiddleware.requestResponseLogger(
            actionLogService: actionLogService,
          ),
        )
        .addHandler(appHandler);
  }

  static Middleware _jsonContentType() {
    return (Handler inner) {
      return (Request request) async {
        final response = await inner(request);
        final ct = response.headers['content-type'] ?? '';
        if (ct.isEmpty || ct.startsWith('text/plain')) {
          final body = await response.readAsString();
          if (body.startsWith('{') || body.startsWith('[')) {
            return response.change(
              body: body,
              headers: {
                ...response.headers,
                'content-type': 'application/json'
              },
            );
          }
          return response.change(body: body);
        }
        return response;
      };
    };
  }
}
