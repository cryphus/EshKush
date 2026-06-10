import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/Routes.dart';
import 'DependencyFactory.dart';

class AppRouterFactory {
  static Router create(AppDependencies dependencies) {
    final app = Router();

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

    app.mount('/', dependencies.apiAuthController.router);
    app.mount('/', dependencies.oauthWebController.router);
    app.mount('/points', dependencies.pointController.router);
    app.mount('/cities', dependencies.cityController.router);
    app.mount('/partners', dependencies.partnerController.router);
    app.mount('/partner-settings', dependencies.partnerSettingsController.router);
    app.mount('/users', dependencies.userController.router);
    app.mount('/favorites', dependencies.userFavoriteController.router);
    app.mount('/users/favorites', dependencies.userFavoriteController.router);
    app.mount('/profiles', dependencies.profileController.router);
    app.mount('/sessions', dependencies.userSessionController.router);
    app.mount('/changes', dependencies.changesController.router);
    app.mount('/point-categories', dependencies.pointCategoryController.router);
    app.mount('/product-categories', dependencies.productCategoryController.router);
    app.mount('/promo-codes', dependencies.promoCodesController.router);
    app.mount('/reviews', dependencies.pointReviewController.router);
    app.mount('/products', dependencies.productsController.router);
    app.mount('/orders', dependencies.orderController.router);
    app.mount('/order-actions', dependencies.orderActionsController.router);
    app.mount('/order-history', dependencies.orderHistoryController.router);
    app.mount('/partner-statistics', dependencies.partnerStatisticsController.router);
    app.mount('/action-logs', dependencies.actionLogController.router);
    app.mount('/error-logs', dependencies.errorLogsController.router);
    app.mount('/cache', dependencies.cacheController.router);
    app.mount('/notifications', dependencies.notificationController.router);
    app.mount('/payment-transactions', dependencies.paymentTransactionsController.router);
    app.mount('/payments', dependencies.paymentGatewayController.router);
    app.mount('/swagger', dependencies.swaggerController.router);
    app.mount('/health', dependencies.healthController.router);

    return app;
  }

  static List<String> get openPaths =>
      Routes.openPathSegments + ['payments/webhook'];
}
