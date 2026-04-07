import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/database/Database.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/middleware/SecurityMiddleware.dart';
import 'package:backend/middleware/CorsMiddleware.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/config/AppConfig.dart';
import 'package:backend/config/Routes.dart';
import 'package:backend/controllers/AuthController.dart';
import 'package:backend/controllers/PointController.dart';
import 'package:backend/services/PointService.dart';
import 'package:backend/repositories/PointRepository.dart';
import 'package:backend/controllers/CityController.dart';
import 'package:backend/services/CityService.dart';
import 'package:backend/repositories/CityRepository.dart';
import 'package:backend/controllers/PartnerController.dart';
import 'package:backend/services/PartnerService.dart';
import 'package:backend/repositories/PartnerRepository.dart';
import 'package:backend/services/UserService.dart';
import 'package:backend/controllers/UserController.dart';
import 'package:backend/controllers/UserFavoriteController.dart';
import 'package:backend/services/UserFavoriteService.dart';
import 'package:backend/repositories/UserFavoriteRepository.dart';
import 'package:backend/controllers/UserSessionController.dart';
import 'package:backend/services/UserSessionService.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/controllers/ProfileController.dart';
import 'package:backend/services/ProfileService.dart';
import 'package:backend/repositories/ProfileRepository.dart';
import 'package:backend/controllers/ChangesController.dart';
import 'package:backend/services/ChangesService.dart';
import 'package:backend/repositories/ChangesRepository.dart';
import 'package:backend/repositories/PartnerSettingsRepository.dart';
import 'package:backend/services/PartnerSettingsService.dart';
import 'package:backend/controllers/PartnerSettingsController.dart';
import 'package:backend/controllers/PointCategoryController.dart';
import 'package:backend/services/PointCategoryService.dart';
import 'package:backend/repositories/PointCategoryRepository.dart';
import 'package:backend/controllers/ProductCategoryController.dart';
import 'package:backend/repositories/ProductCategoryRepository.dart';
import 'package:backend/services/ProductCategoryService.dart';
import 'package:backend/controllers/PromoCodesController.dart';
import 'package:backend/services/PromoCodesService.dart';
import 'package:backend/repositories/PromoCodesRepository.dart';
import 'package:backend/controllers/PointReviewController.dart';
import 'package:backend/services/PointReviewService.dart';
import 'package:backend/repositories/PointReviewRepository.dart';
import 'package:backend/controllers/ProductsController.dart';
import 'package:backend/services/ProductsService.dart';
import 'package:backend/repositories/ProductsRepository.dart';
import 'package:backend/controllers/OrderController.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/controllers/OrderActionsController.dart';
import 'package:backend/services/OrderActionsService.dart';
import 'package:backend/repositories/OrderActionsRepository.dart';
import 'package:backend/controllers/OrderHistoryController.dart';
import 'package:backend/services/OrderHistoryService.dart';
import 'package:backend/repositories/OrderHistoryRepository.dart';
import 'package:backend/controllers/PartnerStatisticsController.dart';
import 'package:backend/services/PartnerStatisticsService.dart';
import 'package:backend/repositories/PartnerStatisticsRepository.dart';
import 'package:backend/controllers/ActionLogController.dart';
import 'package:backend/services/ActionLogService.dart';
import 'package:backend/repositories/ActionLogRepository.dart';
import 'package:backend/controllers/ErrorLogsController.dart';
import 'package:backend/services/ErrorLogsService.dart';
import 'package:backend/repositories/ErrorLogsRepository.dart';
import 'package:backend/controllers/CacheController.dart';
import 'package:backend/controllers/NotificationController.dart';
import 'package:backend/controllers/SwaggerController.dart';
import 'package:backend/services/NotificationService.dart';
import 'package:backend/repositories/NotificationRepository.dart';
import 'package:backend/controllers/PaymentTransactionsController.dart';
import 'package:backend/services/PaymentTransactionsService.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:backend/middleware/LoggingMiddleware.dart';
import 'package:backend/middleware/RbacMiddleware.dart';
import 'package:backend/controllers/HealthController.dart';
import 'package:backend/utils/RateLimiterStore.dart';
import 'package:backend/utils/LoggingUtils.dart';

void main() async {
  try {
    // Инициализация конфигурации
    final config = AppConfig();
    await config.initialize();
    
    // Инициализация кеша
    final cacheService = CacheService();
    await cacheService.initialize();
    
    final db = await Database.instance;
    final userRepository = UserRepository(db.connection);
    final userSessionRepository = UserSessionRepository(db.connection);
    final authService = AuthService(userRepository, userSessionRepository);
    final changesRepository = ChangesRepository(db.connection);
    final changesService = ChangesService(changesRepository);
    final userService = UserService(userRepository, cacheService);
    final userController = UserController(userService);
    final userFavoriteController = UserFavoriteController(
      UserFavoriteService(
        UserFavoriteRepository(db.connection),
      ),
    );
    final userSessionController = UserSessionController(
      UserSessionService(
        userSessionRepository,
      ),
    );
    final pointRepository = PointRepository(db.connection);
    final pointService = PointService(pointRepository, cacheService);
    final pointController = PointController(pointService);
    final cityRepository = CityRepository(db.connection);
    final cityService = CityService(cityRepository);
    final cityController = CityController(cityService);
    final partnerRepository = PartnerRepository(db.connection);
    final partnerService = PartnerService(partnerRepository);
    final partnerController = PartnerController(partnerService);
    final partnerSettingsRepository = PartnerSettingsRepository(db.connection);
    final partnerSettingsService = PartnerSettingsService(partnerSettingsRepository);
    final partnerSettingsController = PartnerSettingsController(partnerSettingsService);
    final profileRepository = ProfileRepository(db.connection);
    final profileService = ProfileService(profileRepository);
    final profileController = ProfileController(profileService);
    final changesController = ChangesController(changesService);
    final pointCategoryRepository = PointCategoryRepository(db.connection);
    final pointCategoryService = PointCategoryService(pointCategoryRepository);
    final pointCategoryController = PointCategoryController(pointCategoryService);
    final productCategoryRepository = ProductCategoryRepository(db.connection);
    final productCategoryService = ProductCategoryService(productCategoryRepository);
    final productCategoryController = ProductCategoryController(productCategoryService);
    final promoCodesRepository = PromoCodesRepository(db.connection);
    final promoCodesService = PromoCodesService(promoCodesRepository);
    final promoCodesController = PromoCodesController(promoCodesService);
    final pointReviewRepository = PointReviewRepository(db.connection);
    final pointReviewService = PointReviewService(pointReviewRepository);
    final pointReviewController = PointReviewController(pointReviewService);
    final productsRepository = ProductsRepository(db.connection);
    final productsService = ProductsService(productsRepository, cacheService);
    final productsController = ProductsController(productsService);
    final orderRepository = OrderRepository(db.connection);
    final orderService = OrderService(
      orderRepository,
      userRepository,
      pointRepository,
      productsRepository
    );
    final orderController = OrderController(orderService);
    final orderActionsController = OrderActionsController(
      OrderActionsService(
        OrderActionsRepository(db.connection),
      ),
    );

    final orderHistoryController = OrderHistoryController(
      OrderHistoryService(
        OrderHistoryRepository(db.connection),
      ),
    );

    final partnerStatisticsController = PartnerStatisticsController(
      PartnerStatisticsService(
        PartnerStatisticsRepository(db.connection),
      ),
    );

    final actionLogController = ActionLogController(
      ActionLogService(
        ActionLogRepository(db.connection),
      ),
    );

    final errorLogsController = ErrorLogsController(
      ErrorLogsService(
        ErrorLogsRepository(db.connection),
      ),
    );
    final cacheController = CacheController(cacheService);

    final notificationController = NotificationController(
      NotificationService(
        NotificationRepository(db.connection),
      ),
    );

    final paymentTransactionsController = PaymentTransactionsController(
      PaymentTransactionsService(
        PaymentTransactionsRepository(db.connection),
      ),
    );

    final swaggerController = SwaggerController();
    final healthController = HealthController(db.connection, cacheService);

    final app = Router();

    final authController = AuthController(
      authService,
      userRepository,
      userSessionRepository,
    );

    final corsMiddleware = CorsMiddleware(allowedOrigins: config.allowedOrigins).call();

    // Корневой маршрут
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

    // Монтирование из конфига Routes (один цикл, без дублирования путей)
    final routers = [
      authController.router,
      pointController.router,
      cityController.router,
      partnerController.router,
      partnerSettingsController.router,
      userController.router,
      userFavoriteController.router, // монтируется на /favorites
      userFavoriteController.router, // монтируется на /users/favorites (тот же контроллер, два пути)
      profileController.router,
      userSessionController.router,
      changesController.router,
      pointCategoryController.router,
      productCategoryController.router,
      promoCodesController.router,
      pointReviewController.router,
      productsController.router,
      orderController.router,
      orderActionsController.router,
      orderHistoryController.router,
      partnerStatisticsController.router,
      actionLogController.router,
      errorLogsController.router,
      cacheController.router,
      notificationController.router,
      paymentTransactionsController.router,
      swaggerController.router,
      healthController.router,
    ];
    for (var i = 0; i < Routes.mountPathsInOrder.length; i++) {
      app.mount(Routes.mountPathsInOrder[i], routers[i]);
    }

    // Rate limiter: Redis в production, InMemory в dev/test
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
            userSessionRepository,
            openPaths: Routes.openPathSegments,
          ),
        )
        .addMiddleware(RbacMiddleware.withRoleRules(Routes.rbacRoleRules))
        .addMiddleware(LoggingMiddleware.requestResponseLogger())
        .addHandler(app.call);

    final server = await io.serve(handler, '0.0.0.0', config.port);
    print('Сервер запущен на http://localhost:${server.port}');

    // Запуск API-тестов если задана переменная окружения RUN_TESTS=true
    if (Platform.environment['RUN_TESTS'] == 'true') {
      _runApiTests(); // intentionally not awaited — сервер продолжает работу
    }

    Timer.periodic(const Duration(minutes: 15), (_) async {
      try {
        final n = await userSessionRepository.cleanupExpiredSessions();
        await userSessionRepository.cleanupExpiredBlacklist();
        if (n > 0) print('Очистка сессий: удалено $n истёкших записей');
      } catch (e) {
        print('Ошибка периодической очистки сессий: $e');
      }
    });
  } catch (e, stackTrace) {
    print('Ошибка запуска сервера: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Запускает скомпилированный тест-бинарник (Docker) или dart-скрипт (локально).
/// Вызывается асинхронно — сервер не блокируется.
Future<void> _runApiTests() async {
  // Дать серверу секунду полностью инициализироваться перед тестами
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\n[API Tests] ══════════════════════════════════════════');
  print('[API Tests] Запуск тестов...');

  try {
    final binDir = File(Platform.resolvedExecutable).parent.path;
    final compiled = File('$binDir/api_test');

    late Process proc;
    if (compiled.existsSync()) {
      // Docker: скомпилированный бинарник рядом с сервером
      proc = await Process.start(
        compiled.path, [],
        mode: ProcessStartMode.inheritStdio,
      );
    } else {
      // Локальная разработка: запуск через dart run
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
