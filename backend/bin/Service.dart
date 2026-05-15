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
// import 'package:path/path.dart' as p;
// import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:backend/middleware/LoggingMiddleware.dart';
import 'package:backend/middleware/RbacMiddleware.dart';
import 'package:backend/utils/LoggingUtils.dart';
import 'package:backend/config/Routes.dart';
import 'package:backend/bootstrap/DependencyFactory.dart';

void main() async {
  try {
    final config = AppConfig();
    await config.initialize();

    final cacheService = CacheService();
    await cacheService.initialize();

    final db = await Database.instance;
    final dependencies = await DependencyFactory.create(
      config: config,
      cacheService: cacheService,
      db: db,
    );
    final userSessionRepository = dependencies.userSessionRepository;
    final actionLogService = dependencies.actionLogService;
    final yooKassaService = dependencies.yooKassaService;
    final apiAuthController = dependencies.apiAuthController;

    final pointController = dependencies.pointController;
    final cityController = dependencies.cityController;
    final partnerController = dependencies.partnerController;
    final partnerSettingsController = dependencies.partnerSettingsController;
    final userController = dependencies.userController;
    final userFavoriteController = dependencies.userFavoriteController;
    final userSessionController = dependencies.userSessionController;
    final profileController = dependencies.profileController;
    final changesController = dependencies.changesController;
    final pointCategoryController = dependencies.pointCategoryController;
    final productCategoryController = dependencies.productCategoryController;
    final promoCodesController = dependencies.promoCodesController;
    final pointReviewController = dependencies.pointReviewController;
    final productsController = dependencies.productsController;
    final orderController = dependencies.orderController;
    final orderActionsController = dependencies.orderActionsController;
    final orderHistoryController = dependencies.orderHistoryController;
    final partnerStatisticsController =
        dependencies.partnerStatisticsController;
    final actionLogController = dependencies.actionLogController;
    final errorLogsController = dependencies.errorLogsController;
    final cacheController = dependencies.cacheController;
    final notificationController = dependencies.notificationController;
    final paymentTransactionsController =
        dependencies.paymentTransactionsController;
    final paymentGatewayController = dependencies.paymentGatewayController;
    final oauthWebController = dependencies.oauthWebController;
    final swaggerController = dependencies.swaggerController;
    final healthController = dependencies.healthController;
    // OrderController получает PaymentGatewayService ниже (см. блок payments).
    final app = Router();

    final corsMiddleware = CorsMiddleware(
            allowedOrigins: config.allowedOrigins,
            devMode: config.isDevelopment)
        .call();

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

    app.mount('/', apiAuthController.router);
    app.mount('/', oauthWebController.router);
    app.mount('/points', pointController.router);

    // Подключаем маршруты CityController
    app.mount('/cities', cityController.router);

    // Подключаем маршруты PartnerController
    app.mount('/partners', partnerController.router);

    // Подключаем маршруты PartnerSettingsController
    app.mount('/partner-settings', partnerSettingsController.router);

    // Подключаем маршруты UserController
    app.mount('/users', userController.router);
    // Роуты избранного
    app.mount('/favorites', userFavoriteController.router);
    // Дублируем роуты избранного и под префиксом /users/favorites
    app.mount('/users/favorites', userFavoriteController.router);

    // Подключаем маршруты ProfileController
    app.mount('/profiles', profileController.router);
    // Подключаем маршруты UserSessionController
    app.mount('/sessions', userSessionController.router);

    // Подключаем маршруты ChangesController
    app.mount('/changes', changesController.router);

    // Подключаем маршруты PointCategoryController
    app.mount('/point-categories', pointCategoryController.router);

    // Подключаем маршруты ProductCategoryController
    app.mount('/product-categories', productCategoryController.router);

    // Подключаем маршруты PromoCodesController
    app.mount('/promo-codes', promoCodesController.router);

    // Подключаем маршруты PointReviewController
    app.mount('/reviews', pointReviewController.router);

    // Подключаем маршруты ProductsController
    app.mount('/products', productsController.router);

    // Подключаем маршруты OrderController
    app.mount('/orders', orderController.router);
    // Подключаем маршруты OrderActionsController
    app.mount('/order-actions', orderActionsController.router);
    // Подключаем маршруты OrderHistoryController
    app.mount('/order-history', orderHistoryController.router);
    app.mount('/partner-statistics', partnerStatisticsController.router);
    // Подключаем маршруты ActionLogController
    app.mount('/action-logs', actionLogController.router);
    // Подключаем маршруты ErrorLogsController
    app.mount('/error-logs', errorLogsController.router);
    // Подключаем маршруты CacheController
    app.mount('/cache', cacheController.router);
    // Подключаем маршруты NotificationController
    app.mount('/notifications', notificationController.router);
    // Подключаем маршруты PaymentTransactionsController
    app.mount('/payment-transactions', paymentTransactionsController.router);
    // Подключаем маршруты PaymentGatewayController (интеграция с YooKassa)
    app.mount('/payments', paymentGatewayController.router);

    // Подключаем маршруты Swagger
    app.mount('/swagger', swaggerController.router);

    // Health check endpoint
    app.mount('/health', healthController.router);

    Middleware jsonContentType() {
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

    final openPaths = Routes.openPathSegments + ['payments/webhook'];

    final handler = const Pipeline()
        .addMiddleware(SecurityMiddleware.securityHeaders())
        .addMiddleware(corsMiddleware)
        .addMiddleware(SecurityMiddleware.requestSizeLimit())
        .addMiddleware(SecurityMiddleware.rateLimiter(
          maxRequests: 20,
          window: const Duration(minutes: 1),
          pathPrefixes: const ['login', 'auth/register', 'auth/refresh'],
        ))
        .addMiddleware(jsonContentType())
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
        .addHandler(app.call);

    final server = await io.serve(handler, '0.0.0.0', config.port);
    await LoggingUtils.logInfo('Сервер запущен',
        context: {'port': server.port});

    if (Platform.environment['RUN_TESTS'] == 'true') {
      _runApiTests();
    }

    final cleanupTimer =
        Timer.periodic(config.sessionCleanupInterval, (_) async {
      try {
        final n = await userSessionRepository.cleanupExpiredSessions();
        await userSessionRepository.cleanupExpiredBlacklist();
        if (n > 0)
          await LoggingUtils.logInfo(
              'Очистка сессий: удалено $n истёкших записей');
      } catch (e, st) {
        await LoggingUtils.logError('Ошибка периодической очистки сессий', e,
            stackTrace: st);
      }
    });

    final shutdownCompleter = Completer<void>();
    var isShuttingDown = false;
    StreamSubscription<ProcessSignal>? sigIntSub;
    StreamSubscription<ProcessSignal>? sigTermSub;

    Future<void> shutdown(String signalName) async {
      if (isShuttingDown) return;
      isShuttingDown = true;
      await LoggingUtils.logInfo(
        'Graceful shutdown started',
        context: {'signal': signalName},
      );

      cleanupTimer.cancel();
      await sigIntSub?.cancel();
      await sigTermSub?.cancel();
      yooKassaService.dispose();

      try {
        await server.close(force: true);
      } catch (_) {}

      try {
        await db.connection.close();
      } catch (_) {}

      if (!shutdownCompleter.isCompleted) {
        shutdownCompleter.complete();
      }
    }

    sigIntSub = ProcessSignal.sigint.watch().listen((_) => shutdown('SIGINT'));
    sigTermSub =
        ProcessSignal.sigterm.watch().listen((_) => shutdown('SIGTERM'));

    await shutdownCompleter.future;
  } catch (e, stackTrace) {
    await LoggingUtils.logError('Ошибка запуска сервера', e,
        stackTrace: stackTrace);
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
        compiled.path,
        [],
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
        'dart',
        ['run', script],
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
