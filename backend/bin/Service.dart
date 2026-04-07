import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/database/Database.dart';
import 'package:backend/middleware/SecurityMiddleware.dart';
import 'package:backend/middleware/CorsMiddleware.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/config/Routes.dart';
import 'package:backend/config/DependencyContainer.dart';
import 'package:backend/middleware/LoggingMiddleware.dart';
import 'package:backend/middleware/RbacMiddleware.dart';
import 'package:backend/utils/RateLimiterStore.dart';
import 'package:backend/utils/LoggingUtils.dart';

void main() async {
  try {
    final config = AppConfig();
    await config.initialize();

    final cacheService = CacheService();
    await cacheService.initialize();

    final db = await Database.instance;
    final deps = await DependencyContainer.build(db.connection, cacheService);

    final app = Router();

    final corsMiddleware = CorsMiddleware(allowedOrigins: config.allowedOrigins).call();

    app.get('/', (Request request) {
      return Response.ok(
        jsonEncode({
          'message': 'EshKush API',
          'version': '1.0.0',
          'swagger': '/swagger/',
          'endpoints': {
            'auth': '/auth/google, /auth/register, /auth/refresh, /login',
            'points': '/points',
            'products': '/products',
            'orders': '/orders',
            'users': '/users',
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    for (var i = 0; i < Routes.mountPathsInOrder.length; i++) {
      app.mount(Routes.mountPathsInOrder[i], deps.routers[i]);
    }

    final RateLimiterStore rateLimiterStore;
    if (config.isProduction) {
      rateLimiterStore = await RedisRateLimiterStore.connect(
        config.redisHost,
        config.redisPort,
        password: config.redisPassword.isNotEmpty ? config.redisPassword : null,
        db: config.redisDb,
        timeout: config.redisConnectionTimeout,
      );
      await LoggingUtils.logInfo('Rate limiter: Redis (${config.redisHost}:${config.redisPort})');
    } else {
      rateLimiterStore = InMemoryRateLimiterStore();
      await LoggingUtils.logInfo('Rate limiter: InMemory (только для dev)');
    }

    final handler = const Pipeline()
        .addMiddleware(corsMiddleware)
        .addMiddleware(SecurityMiddleware.securityHeaders())
        .addMiddleware(SecurityMiddleware.rateLimiter(
          store: rateLimiterStore,
          maxRequests: config.rateLimitRequests,
          window: config.rateLimitWindow,
        ))
        .addMiddleware(
          SecurityMiddleware.checkJWT(
            deps.userSessionRepository,
            openPaths: Routes.openPathSegments,
          ),
        )
        .addMiddleware(RbacMiddleware.withRoleRules(Routes.rbacRoleRules))
        .addMiddleware(LoggingMiddleware.requestResponseLogger())
        .addHandler(app.call);

    final server = await io.serve(handler, '0.0.0.0', config.port);
    await LoggingUtils.logInfo('Сервер запущен', context: {'port': server.port});

    if (Platform.environment['RUN_TESTS'] == 'true') {
      _runApiTests();
    }

    Timer.periodic(const Duration(minutes: 15), (_) async {
      try {
        final n = await deps.userSessionRepository.cleanupExpiredSessions();
        await deps.userSessionRepository.cleanupExpiredBlacklist();
        if (n > 0) await LoggingUtils.logInfo('Очистка сессий: удалено $n истёкших записей');
      } catch (e, st) {
        await LoggingUtils.logError('Ошибка периодической очистки сессий', e, stackTrace: st);
      }
    });
  } catch (e, stackTrace) {
    await LoggingUtils.logError('Ошибка запуска сервера', e, stackTrace: stackTrace);
    exit(1);
  }
}

/// Запускает скомпилированный тест-бинарник (Docker) или dart-скрипт (локально).
/// Вызывается асинхронно — сервер не блокируется.
Future<void> _runApiTests() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\n[API Tests] ══════════════════════════════════════════');
  print('[API Tests] Запуск тестов...');

  try {
    final binDir = File(Platform.resolvedExecutable).parent.path;
    final compiled = File('$binDir/api_test');

    late Process proc;
    if (compiled.existsSync()) {
      proc = await Process.start(
        compiled.path, [],
        mode: ProcessStartMode.inheritStdio,
      );
    } else {
      final scriptCandidates = [
        '${Directory.current.path}/test/ApiTest.dart',
        '${File(Platform.script.toFilePath()).parent.parent.path}/test/ApiTest.dart',
      ];
      final script = scriptCandidates.firstWhere(
        (p) => File(p).existsSync(),
        orElse: () => '',
      );
      if (script.isEmpty) {
        print('[API Tests] Файл теста не найден. '
            'Ожидается test/ApiTest.dart в корне проекта.');
        return;
      }
      proc = await Process.start(
        'dart', ['run', script],
        mode: ProcessStartMode.inheritStdio,
      );
    }

    final code = await proc.exitCode;
    print('[API Tests] Завершено с кодом $code');
    print('[API Tests] ══════════════════════════════════════════\n');
  } catch (e) {
    print('[API Tests] Ошибка запуска тестов: $e');
  }
}
