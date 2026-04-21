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
import 'package:backend/controllers/PaymentGatewayController.dart';
import 'package:backend/services/PaymentGatewayService.dart';
import 'package:backend/services/YooKassaService.dart';
import 'package:backend/services/OAuthService.dart';
import 'package:backend/middleware/LoggingMiddleware.dart';
import 'package:backend/middleware/RbacMiddleware.dart';
import 'package:backend/utils/RateLimiterStore.dart';
import 'package:backend/utils/LoggingUtils.dart';
import 'package:backend/utils/AuthUtils.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/config/Routes.dart';
import 'package:backend/model/entities/UserSessions.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() async {
  try {
    final config = AppConfig();
    await config.initialize();

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
    // OrderController получает PaymentGatewayService ниже (см. блок payments).
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

    final paymentTransactionsRepository = PaymentTransactionsRepository(db.connection);
    final paymentTransactionsController = PaymentTransactionsController(
      PaymentTransactionsService(paymentTransactionsRepository),
    );

    final yooKassaService = YooKassaService(config);
    final paymentGatewayService = PaymentGatewayService(
      yooKassaService: yooKassaService,
      transactionsRepository: paymentTransactionsRepository,
      orderRepository: orderRepository,
      orderService: orderService,
      config: config,
    );
    final paymentGatewayController =
        PaymentGatewayController(paymentGatewayService);

    final orderController = OrderController(
      orderService,
      paymentGatewayService: paymentGatewayService,
    );

    final oauthService = OAuthService(config);

    final swaggerController = SwaggerController();

    final app = Router();

    final corsMiddleware = CorsMiddleware(allowedOrigins: config.allowedOrigins, devMode: config.isDevelopment).call();

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

    app.post('/auth/google', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        // Проверяем наличие idToken
        if (data['idToken'] == null) {
          return Response(
            400,
            body: jsonEncode({'error': 'Отсутствует idToken от Google'}),
          );
        }

        // Проверяем валидность Google ID токена
        try {
          final decodedToken = JwtDecoder.decode(data['idToken']);
          final clientId = Platform.environment['GOOGLE_CLIENT_ID'];
          final clientSecret = Platform.environment['GOOGLE_CLIENT_SECRET'];
          
          if (clientId == null || clientSecret == null) {
            throw Exception('Отсутствуют учетные данные Google OAuth2');
          }

          if (decodedToken['iss'] != 'https://accounts.google.com' ||
              decodedToken['aud'] != clientId) {
            return Response(
              401,
              body: jsonEncode({'error': 'Недействительный Google ID токен'}),
            );
          }
        } catch (e) {
          return Response(
            401,
            body: jsonEncode({'error': 'Ошибка проверки Google ID токена: $e'}),
          );
        }
        
        final user = await userRepository.findByEmail(data['email']);
        
        
        if (user != null) {
          final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
          final refreshJti = bundle['refresh_jti'] as String;
          final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

          await userSessionRepository.create(
            UserSessions(
              id: 0,
              userId: user.id,
              createdAt: DateTime.now(),
              expiresAt: refreshExpiresAt,
              lastActive: DateTime.now(),
              userAgent: request.headers['user-agent'] ?? 'unknown',
              ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
              token: bundle['access_token'] as String,
              refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
            ),
          );

          final tokens = {
            'access_token': bundle['access_token'],
            'refresh_token': bundle['refresh_token'],
          };
          return Response.ok(
            jsonEncode({
              ...tokens,
              'user': {
                'email': user.email,
                'username': user.username,
                'role': user.role.name.toLowerCase(),
              }
            }),
          );
        } else {
          return Response(
            404,
            body: jsonEncode({
              'needsRegistration': true,
              'email': data['email'],
              'displayName': data['displayName'],
            }),
          );
        }
      } catch (e) {
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    app.post('/auth/register', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final result = await authService.register(
          data,
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
        );
        
        return Response.ok(
          jsonEncode(result),
        );
      } catch (e) {
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    app.post('/auth/refresh', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        if (data['refresh_token'] == null) {
          return Response(400, body: jsonEncode({'error': 'Требуется refresh_token'}));
        }

        final result = await authService.refreshToken(data['refresh_token']);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response(401, body: jsonEncode({'error': e.toString()}));
      }
    });

    app.post('/login', (Request request) async {
      try {
        final data = jsonDecode(await request.readAsString());
        final result = await authService.login(
          data['username'],
          data['password'],
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
        );
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response(401, body: jsonEncode({'error': e.toString()}));
      }
    });

    app.post('/auth/check_user', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final phoneNumber = data['phoneNumber'] as String;
        
        final user = await userRepository.queryOne(
          '''
          SELECT 
            id,
            username,
            password,
            email,
            number,
            role,
            to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
            CASE 
              WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
              ELSE NULL
            END as updated_at
          FROM users 
          WHERE number = @number
          ''',
          params: {'number': phoneNumber},
        );
        
        return Response.ok(
          jsonEncode({
            'exists': user != null,
            'user': user
          }),
        );
      } catch (e) {
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // ── Yandex OAuth ────────────────────────────────────────────────────────────

    app.get('/auth/yandex', (Request request) {
      if (!config.isYandexConfigured) {
        return Response(503, body: jsonEncode({'error': 'Яндекс OAuth не настроен'}));
      }
      return Response.found(oauthService.buildYandexAuthUrl());
    });

    app.get('/auth/yandex/callback', (Request request) async {
      try {
        final code = request.url.queryParameters['code'];
        final error = request.url.queryParameters['error'];

        if (error != null || code == null) {
          return Response.found('${config.frontendUrl}/?oauth_error=${Uri.encodeComponent(error ?? 'no_code')}');
        }

        final yandexUser = await oauthService.handleYandexCode(code);
        final yandexId = yandexUser['id']?.toString() ?? '';

        if (yandexId.isEmpty) {
          return Response.found('${config.frontendUrl}/?oauth_error=no_id');
        }

        var user = await userRepository.findByYandexId(yandexId);

        if (user == null) {
          // Проверяем, есть ли пользователь с таким email
          final email = yandexUser['default_email'] as String?;
          if (email != null && email.isNotEmpty) {
            try {
              user = await userRepository.findByEmail(email);
              if (user != null) {
                // Привязываем Яндекс ID к существующему аккаунту
                await userRepository.linkYandexId(user.id, yandexId);
              }
            } catch (_) {}
          }

          if (user == null) {
            final login = (yandexUser['login'] as String?) ?? 'ya_$yandexId';
            user = await userRepository.createOAuthUser(
              baseUsername: login,
              email: yandexUser['default_email'] as String?,
              yandexId: yandexId,
              firstName: yandexUser['first_name'] as String?,
              lastName: yandexUser['last_name'] as String?,
            );
          }
        }

        final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
        final refreshJti = bundle['refresh_jti'] as String;
        final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

        await userSessionRepository.create(UserSessions(
          id: 0,
          userId: user.id,
          createdAt: DateTime.now(),
          expiresAt: refreshExpiresAt,
          lastActive: DateTime.now(),
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
          token: bundle['access_token'] as String,
          refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
        ));

        final redirectUrl = Uri.parse(config.frontendUrl).replace(queryParameters: {
          'access_token': bundle['access_token'] as String,
          'refresh_token': bundle['refresh_token'] as String,
        }).toString();

        return Response.found(redirectUrl);
      } catch (e) {
        await LoggingUtils.logError('Yandex OAuth callback error', e);
        return Response.found('${config.frontendUrl}/?oauth_error=${Uri.encodeComponent(e.toString())}');
      }
    });

    // ── VK OAuth ────────────────────────────────────────────────────────────────

    app.get('/auth/vk', (Request request) {
      if (!config.isVkConfigured) {
        return Response(503, body: jsonEncode({'error': 'ВКонтакте OAuth не настроен'}));
      }
      return Response.found(oauthService.buildVkAuthUrl());
    });

    app.get('/auth/vk/callback', (Request request) async {
      try {
        final code = request.url.queryParameters['code'];
        final error = request.url.queryParameters['error'];

        if (error != null || code == null) {
          return Response.found('${config.frontendUrl}/?oauth_error=${Uri.encodeComponent(error ?? 'no_code')}');
        }

        final vkUser = await oauthService.handleVkCode(code);
        final vkId = vkUser['id']?.toString() ?? '';

        if (vkId.isEmpty) {
          return Response.found('${config.frontendUrl}/?oauth_error=no_id');
        }

        var user = await userRepository.findByVkId(vkId);

        if (user == null) {
          final email = vkUser['email'] as String?;
          if (email != null && email.isNotEmpty) {
            try {
              user = await userRepository.findByEmail(email);
              if (user != null) {
                await userRepository.linkVkId(user.id, vkId);
              }
            } catch (_) {}
          }

          if (user == null) {
            final firstName = vkUser['first_name'] as String? ?? '';
            final lastName = vkUser['last_name'] as String? ?? '';
            final baseUsername = firstName.isNotEmpty ? '${firstName.toLowerCase()}_vk' : 'vk_$vkId';
            user = await userRepository.createOAuthUser(
              baseUsername: baseUsername,
              email: email,
              vkId: vkId,
              firstName: firstName.isNotEmpty ? firstName : null,
              lastName: lastName.isNotEmpty ? lastName : null,
            );
          }
        }

        final bundle = AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
        final refreshJti = bundle['refresh_jti'] as String;
        final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

        await userSessionRepository.create(UserSessions(
          id: 0,
          userId: user.id,
          createdAt: DateTime.now(),
          expiresAt: refreshExpiresAt,
          lastActive: DateTime.now(),
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
          token: bundle['access_token'] as String,
          refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
        ));

        final redirectUrl = Uri.parse(config.frontendUrl).replace(queryParameters: {
          'access_token': bundle['access_token'] as String,
          'refresh_token': bundle['refresh_token'] as String,
        }).toString();

        return Response.found(redirectUrl);
      } catch (e) {
        await LoggingUtils.logError('VK OAuth callback error', e);
        return Response.found('${config.frontendUrl}/?oauth_error=${Uri.encodeComponent(e.toString())}');
      }
    });

    // Подключаем маршруты PointController
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
    app.mount('/order-history', orderHistoryController.router);
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
                headers: {...response.headers, 'content-type': 'application/json'},
              );
            }
            return response.change(body: body);
          }
          return response;
        };
      };
    }

    final handler = const Pipeline()
        .addMiddleware(corsMiddleware)
        .addMiddleware(jsonContentType())
        .addMiddleware(SecurityMiddleware.checkJWT(
          userSessionRepository,
          openPaths: Routes.openPathSegments + ['payments/webhook'],
        ))
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
        final n = await userSessionRepository.cleanupExpiredSessions();
        await userSessionRepository.cleanupExpiredBlacklist();
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
