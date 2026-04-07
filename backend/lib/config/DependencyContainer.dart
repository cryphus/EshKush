import 'package:postgres/postgres.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/repositories/UserSessionRepository.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/controllers/AuthController.dart';
import 'package:backend/repositories/ChangesRepository.dart';
import 'package:backend/services/ChangesService.dart';
import 'package:backend/controllers/ChangesController.dart';
import 'package:backend/services/UserService.dart';
import 'package:backend/controllers/UserController.dart';
import 'package:backend/controllers/UserFavoriteController.dart';
import 'package:backend/services/UserFavoriteService.dart';
import 'package:backend/repositories/UserFavoriteRepository.dart';
import 'package:backend/controllers/UserSessionController.dart';
import 'package:backend/services/UserSessionService.dart';
import 'package:backend/repositories/PointRepository.dart';
import 'package:backend/services/PointService.dart';
import 'package:backend/controllers/PointController.dart';
import 'package:backend/repositories/CityRepository.dart';
import 'package:backend/services/CityService.dart';
import 'package:backend/controllers/CityController.dart';
import 'package:backend/repositories/PartnerRepository.dart';
import 'package:backend/services/PartnerService.dart';
import 'package:backend/controllers/PartnerController.dart';
import 'package:backend/repositories/PartnerSettingsRepository.dart';
import 'package:backend/services/PartnerSettingsService.dart';
import 'package:backend/controllers/PartnerSettingsController.dart';
import 'package:backend/repositories/ProfileRepository.dart';
import 'package:backend/services/ProfileService.dart';
import 'package:backend/controllers/ProfileController.dart';
import 'package:backend/repositories/PointCategoryRepository.dart';
import 'package:backend/services/PointCategoryService.dart';
import 'package:backend/controllers/PointCategoryController.dart';
import 'package:backend/repositories/ProductCategoryRepository.dart';
import 'package:backend/services/ProductCategoryService.dart';
import 'package:backend/controllers/ProductCategoryController.dart';
import 'package:backend/repositories/PromoCodesRepository.dart';
import 'package:backend/services/PromoCodesService.dart';
import 'package:backend/controllers/PromoCodesController.dart';
import 'package:backend/repositories/PointReviewRepository.dart';
import 'package:backend/services/PointReviewService.dart';
import 'package:backend/controllers/PointReviewController.dart';
import 'package:backend/repositories/ProductsRepository.dart';
import 'package:backend/services/ProductsService.dart';
import 'package:backend/controllers/ProductsController.dart';
import 'package:backend/repositories/OrderRepository.dart';
import 'package:backend/services/OrderService.dart';
import 'package:backend/controllers/OrderController.dart';
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
import 'package:backend/services/NotificationService.dart';
import 'package:backend/repositories/NotificationRepository.dart';
import 'package:backend/controllers/PaymentTransactionsController.dart';
import 'package:backend/services/PaymentTransactionsService.dart';
import 'package:backend/repositories/PaymentTransactionsRepository.dart';
import 'package:backend/controllers/SwaggerController.dart';
import 'package:backend/controllers/HealthController.dart';

class DependencyContainer {
  final UserSessionRepository userSessionRepository;

  final AuthController authController;
  final PointController pointController;
  final CityController cityController;
  final PartnerController partnerController;
  final PartnerSettingsController partnerSettingsController;
  final UserController userController;
  final UserFavoriteController userFavoriteController;
  final ProfileController profileController;
  final UserSessionController userSessionController;
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
  final SwaggerController swaggerController;
  final HealthController healthController;

  DependencyContainer._({
    required this.userSessionRepository,
    required this.authController,
    required this.pointController,
    required this.cityController,
    required this.partnerController,
    required this.partnerSettingsController,
    required this.userController,
    required this.userFavoriteController,
    required this.profileController,
    required this.userSessionController,
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
    required this.swaggerController,
    required this.healthController,
  });

  static Future<DependencyContainer> build(
    PostgreSQLConnection conn,
    CacheService cacheService,
  ) async {
    final userRepository = UserRepository(conn);
    final userSessionRepository = UserSessionRepository(conn);
    final authService = AuthService(userRepository, userSessionRepository);
    final changesRepository = ChangesRepository(conn);
    final changesService = ChangesService(changesRepository);
    final userService = UserService(userRepository, cacheService);
    final pointRepository = PointRepository(conn);
    final pointService = PointService(pointRepository, cacheService);
    final cityRepository = CityRepository(conn);
    final cityService = CityService(cityRepository);
    final partnerRepository = PartnerRepository(conn);
    final partnerService = PartnerService(partnerRepository);
    final partnerSettingsRepository = PartnerSettingsRepository(conn);
    final partnerSettingsService = PartnerSettingsService(partnerSettingsRepository);
    final profileRepository = ProfileRepository(conn);
    final profileService = ProfileService(profileRepository);
    final pointCategoryRepository = PointCategoryRepository(conn);
    final pointCategoryService = PointCategoryService(pointCategoryRepository);
    final productCategoryRepository = ProductCategoryRepository(conn);
    final productCategoryService = ProductCategoryService(productCategoryRepository);
    final promoCodesRepository = PromoCodesRepository(conn);
    final promoCodesService = PromoCodesService(promoCodesRepository);
    final pointReviewRepository = PointReviewRepository(conn);
    final pointReviewService = PointReviewService(pointReviewRepository);
    final productsRepository = ProductsRepository(conn);
    final productsService = ProductsService(productsRepository, cacheService);
    final orderRepository = OrderRepository(conn);
    final orderService = OrderService(
      orderRepository,
      userRepository,
      pointRepository,
      productsRepository,
    );

    return DependencyContainer._(
      userSessionRepository: userSessionRepository,
      authController: AuthController(authService, userRepository, userSessionRepository),
      pointController: PointController(pointService),
      cityController: CityController(cityService),
      partnerController: PartnerController(partnerService),
      partnerSettingsController: PartnerSettingsController(partnerSettingsService),
      userController: UserController(userService),
      userFavoriteController: UserFavoriteController(
        UserFavoriteService(UserFavoriteRepository(conn)),
      ),
      profileController: ProfileController(profileService),
      userSessionController: UserSessionController(
        UserSessionService(userSessionRepository),
      ),
      changesController: ChangesController(changesService),
      pointCategoryController: PointCategoryController(pointCategoryService),
      productCategoryController: ProductCategoryController(productCategoryService),
      promoCodesController: PromoCodesController(promoCodesService),
      pointReviewController: PointReviewController(pointReviewService),
      productsController: ProductsController(productsService),
      orderController: OrderController(orderService),
      orderActionsController: OrderActionsController(
        OrderActionsService(OrderActionsRepository(conn)),
      ),
      orderHistoryController: OrderHistoryController(
        OrderHistoryService(OrderHistoryRepository(conn)),
      ),
      partnerStatisticsController: PartnerStatisticsController(
        PartnerStatisticsService(PartnerStatisticsRepository(conn)),
      ),
      actionLogController: ActionLogController(
        ActionLogService(ActionLogRepository(conn)),
      ),
      errorLogsController: ErrorLogsController(
        ErrorLogsService(ErrorLogsRepository(conn)),
      ),
      cacheController: CacheController(cacheService),
      notificationController: NotificationController(
        NotificationService(NotificationRepository(conn)),
      ),
      paymentTransactionsController: PaymentTransactionsController(
        PaymentTransactionsService(PaymentTransactionsRepository(conn)),
      ),
      swaggerController: SwaggerController(),
      healthController: HealthController(conn, cacheService),
    );
  }

  /// Список роутеров в порядке, соответствующем Routes.mountPathsInOrder.
  List<Router> get routers => [
    authController.router,
    pointController.router,
    cityController.router,
    partnerController.router,
    partnerSettingsController.router,
    userController.router,
    userFavoriteController.router,
    userFavoriteController.router, // монтируется на /users/favorites (тот же контроллер)
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
}
