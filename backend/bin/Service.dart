import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/database/Database.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/utils/AuthUtils.dart';
import 'package:path/path.dart' as p;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
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
import 'package:backend/controllers/NotificationController.dart';
import 'package:backend/services/NotificationService.dart';
import 'package:backend/repositories/NotificationRepository.dart';
import 'package:backend/controllers/PaymentTransactionsController.dart';
import 'package:backend/services/PaymentTransactionsService.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() async {
  try {
    final db = await Database.instance;
    final userRepository = UserRepository(db.connection);
    final authService = AuthService(userRepository);
    final changesRepository = ChangesRepository(db.connection);
    final changesService = ChangesService(changesRepository);
    final userService = UserService(userRepository);
    final userController = UserController(userService);
    final userFavoriteController = UserFavoriteController(
      UserFavoriteService(
        UserFavoriteRepository(db.connection),
      ),
    );
    final userSessionController = UserSessionController(
      UserSessionService(
        UserSessionRepository(db.connection),
      ),
    );
    final pointRepository = PointRepository(db.connection);
    final pointService = PointService(pointRepository);
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
    final productsService = ProductsService(productsRepository);
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

    final app = Router();

    final corsHandler = createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
          });
        }
        return null;
      },
    );

    app.post('/auth/google', (Request request) async {
      try {
        print('Получен запрос на аутентификацию через Google');
        final body = await request.readAsString();
        print('Тело запроса: $body');
        final data = jsonDecode(body);
        print('Данные запроса: $data');
        
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
        print('Найденный пользователь: $user');
        
        if (user != null) {
          final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());
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
        print('Ошибка аутентификации через Google: $e');
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    app.post('/auth/register', (Request request) async {
      try {
        print('Получен запрос на регистрацию');
        final body = await request.readAsString();
        final data = jsonDecode(body);
        print('Данные регистрации: $data');
        
        final result = await authService.register(data);
        
        return Response.ok(
          jsonEncode(result),
        );
      } catch (e) {
        print('Ошибка регистрации: $e');
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
        print('Ошибка проверки пользователя: $e');
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
        );
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
    // Подключаем маршруты NotificationController
    app.mount('/notifications', notificationController.router);
    // Подключаем маршруты PaymentTransactionsController
    app.mount('/payment-transactions', paymentTransactionsController.router);

    final handler = const Pipeline()
        .addMiddleware(corsHandler)
        .addMiddleware(logRequests())
        .addHandler(app.call);

    final server = await io.serve(handler, '0.0.0.0', 8080);
    print('Сервер запущен на http://localhost:${server.port}');
  } catch (e, stackTrace) {
    print('Ошибка запуска сервера: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
