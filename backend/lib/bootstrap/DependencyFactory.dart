import '../config/AppConfig.dart';
import '../controllers/ActionLogController.dart';
import '../controllers/ApiAuthController.dart';
import '../controllers/CacheController.dart';
import '../controllers/ChangesController.dart';
import '../controllers/CityController.dart';
import '../controllers/ErrorLogsController.dart';
import '../controllers/HealthController.dart';
import '../controllers/NotificationController.dart';
import '../controllers/OAuthWebController.dart';
import '../controllers/OrderActionsController.dart';
import '../controllers/OrderController.dart';
import '../controllers/OrderHistoryController.dart';
import '../controllers/PartnerController.dart';
import '../controllers/PartnerSettingsController.dart';
import '../controllers/PartnerStatisticsController.dart';
import '../controllers/PaymentGatewayController.dart';
import '../controllers/PaymentTransactionsController.dart';
import '../controllers/PointCategoryController.dart';
import '../controllers/PointController.dart';
import '../controllers/PointReviewController.dart';
import '../controllers/ProductCategoryController.dart';
import '../controllers/ProductsController.dart';
import '../controllers/ProfileController.dart';
import '../controllers/PromoCodesController.dart';
import '../controllers/SwaggerController.dart';
import '../controllers/UserController.dart';
import '../controllers/UserFavoriteController.dart';
import '../controllers/UserSessionController.dart';
import '../database/Database.dart';
import '../repositories/ActionLogRepository.dart';
import '../repositories/ChangesRepository.dart';
import '../repositories/CityRepository.dart';
import '../repositories/ErrorLogsRepository.dart';
import '../repositories/NotificationRepository.dart';
import '../repositories/OrderActionsRepository.dart';
import '../repositories/OrderHistoryRepository.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/PartnerRepository.dart';
import '../repositories/PartnerSettingsRepository.dart';
import '../repositories/PartnerStatisticsRepository.dart';
import '../repositories/PaymentTransactionsRepository.dart';
import '../repositories/PointCategoryRepository.dart';
import '../repositories/PointRepository.dart';
import '../repositories/PointReviewRepository.dart';
import '../repositories/ProductCategoryRepository.dart';
import '../repositories/ProductsRepository.dart';
import '../repositories/PromoCodesRepository.dart';
import '../repositories/ProfileRepository.dart';
import '../repositories/UserFavoriteRepository.dart';
import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../services/ActionLogService.dart';
import '../services/AuthService.dart';
import '../services/CacheService.dart';
import '../services/ChangesService.dart';
import '../services/CityService.dart';
import '../services/ErrorLogsService.dart';
import '../services/NotificationService.dart';
import '../services/OAuthService.dart';
import '../services/OrderActionsService.dart';
import '../services/OrderHistoryService.dart';
import '../services/OrderService.dart';
import '../services/PartnerService.dart';
import '../services/PartnerSettingsService.dart';
import '../services/PartnerStatisticsService.dart';
import '../services/PaymentGatewayService.dart';
import '../services/PaymentTransactionsService.dart';
import '../services/PointCategoryService.dart';
import '../services/PointReviewService.dart';
import '../services/PointService.dart';
import '../services/ProductCategoryService.dart';
import '../services/ProductsService.dart';
import '../services/ProfileService.dart';
import '../services/PromoCodesService.dart';
import '../services/UserFavoriteService.dart';
import '../services/UserService.dart';
import '../services/UserSessionService.dart';
import '../services/YooKassaService.dart';

class AppDependencies {
  final UserRepository userRepository;
  final UserSessionRepository userSessionRepository;
  final AuthService authService;
  final ActionLogService actionLogService;
  final YooKassaService yooKassaService;
  final ApiAuthController apiAuthController;

  final PointController pointController;
  final CityController cityController;
  final PartnerController partnerController;
  final PartnerSettingsController partnerSettingsController;
  final UserController userController;
  final UserFavoriteController userFavoriteController;
  final UserSessionController userSessionController;
  final ProfileController profileController;
  final ChangesController changesController;
  final PointCategoryController pointCategoryController;
  final ProductCategoryController productCategoryController;
  final PromoCodesController promoCodesController;
  final PointReviewController pointReviewController;
  final ProductsController productsController;
  final OrderController orderController;
  final OrderActionsController orderActionsController;
  final OrderHistoryController orderHistoryController;
  final PartnerStatisticsController partnerStatisticsController;
  final ActionLogController actionLogController;
  final ErrorLogsController errorLogsController;
  final CacheController cacheController;
  final NotificationController notificationController;
  final PaymentTransactionsController paymentTransactionsController;
  final PaymentGatewayController paymentGatewayController;
  final OAuthWebController oauthWebController;
  final SwaggerController swaggerController;
  final HealthController healthController;

  AppDependencies({
    required this.userRepository,
    required this.userSessionRepository,
    required this.authService,
    required this.actionLogService,
    required this.yooKassaService,
    required this.apiAuthController,
    required this.pointController,
    required this.cityController,
    required this.partnerController,
    required this.partnerSettingsController,
    required this.userController,
    required this.userFavoriteController,
    required this.userSessionController,
    required this.profileController,
    required this.changesController,
    required this.pointCategoryController,
    required this.productCategoryController,
    required this.promoCodesController,
    required this.pointReviewController,
    required this.productsController,
    required this.orderController,
    required this.orderActionsController,
    required this.orderHistoryController,
    required this.partnerStatisticsController,
    required this.actionLogController,
    required this.errorLogsController,
    required this.cacheController,
    required this.notificationController,
    required this.paymentTransactionsController,
    required this.paymentGatewayController,
    required this.oauthWebController,
    required this.swaggerController,
    required this.healthController,
  });
}

class DependencyFactory {
  static Future<AppDependencies> create({
    required AppConfig config,
    required CacheService cacheService,
    required Database db,
  }) async {
    final userRepository = UserRepository(db.connection);
    final userSessionRepository = UserSessionRepository(db.connection);
    final authService = AuthService(userRepository, userSessionRepository);
    final apiAuthController = ApiAuthController(
      authService,
      userRepository,
      userSessionRepository,
    );
    final changesRepository = ChangesRepository(db.connection);
    final changesService = ChangesService(changesRepository);
    final userService = UserService(
      userRepository,
      cacheService,
      sessionRepository: userSessionRepository,
    );
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
    final partnerSettingsService =
        PartnerSettingsService(partnerSettingsRepository);
    final partnerSettingsController =
        PartnerSettingsController(partnerSettingsService);
    final profileRepository = ProfileRepository(db.connection);
    final profileService = ProfileService(profileRepository);
    final profileController = ProfileController(profileService);
    final changesController = ChangesController(changesService);
    final pointCategoryRepository = PointCategoryRepository(db.connection);
    final pointCategoryService = PointCategoryService(pointCategoryRepository);
    final pointCategoryController =
        PointCategoryController(pointCategoryService);
    final productCategoryRepository = ProductCategoryRepository(db.connection);
    final productCategoryService =
        ProductCategoryService(productCategoryRepository);
    final productCategoryController =
        ProductCategoryController(productCategoryService);
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
      productsRepository,
    );
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

    final actionLogService = ActionLogService(
      ActionLogRepository(db.connection),
    );
    final actionLogController = ActionLogController(actionLogService);

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

    final paymentTransactionsRepository =
        PaymentTransactionsRepository(db.connection);
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
    final oauthWebController = OAuthWebController(
      config,
      oauthService,
      userRepository,
      userSessionRepository,
    );

    final swaggerController = SwaggerController();
    final healthController = HealthController(db.connection, cacheService);

    return AppDependencies(
      userRepository: userRepository,
      userSessionRepository: userSessionRepository,
      authService: authService,
      actionLogService: actionLogService,
      yooKassaService: yooKassaService,
      apiAuthController: apiAuthController,
      pointController: pointController,
      cityController: cityController,
      partnerController: partnerController,
      partnerSettingsController: partnerSettingsController,
      userController: userController,
      userFavoriteController: userFavoriteController,
      userSessionController: userSessionController,
      profileController: profileController,
      changesController: changesController,
      pointCategoryController: pointCategoryController,
      productCategoryController: productCategoryController,
      promoCodesController: promoCodesController,
      pointReviewController: pointReviewController,
      productsController: productsController,
      orderController: orderController,
      orderActionsController: orderActionsController,
      orderHistoryController: orderHistoryController,
      partnerStatisticsController: partnerStatisticsController,
      actionLogController: actionLogController,
      errorLogsController: errorLogsController,
      cacheController: cacheController,
      notificationController: notificationController,
      paymentTransactionsController: paymentTransactionsController,
      paymentGatewayController: paymentGatewayController,
      oauthWebController: oauthWebController,
      swaggerController: swaggerController,
      healthController: healthController,
    );
  }
}
