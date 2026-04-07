/// Централизованные маршруты и открытые пути API.
/// Используется в SecurityMiddleware.checkJWT (openPaths) и для монтирования в Service.
class Routes {
  Routes._();

  /// Пути (или префиксы), для которых не требуется JWT.
  /// checkJWT пропускает запросы, у которых path.startsWith(segment) для любого segment.
  /// Формат path в Shelf — БЕЗ ведущего слэша (request.url.path).
  static const List<String> openPathSegments = [
    'auth',
    'login',
    'swagger',
    'health',
  ];

  /// Порядок путей монтирования (единый источник правды для app.mount в Service).
  /// Корень '/' — auth (корень API), остальные с ведущим слэшем.
  static const List<String> mountPathsInOrder = [
    '/',
    '/points',
    '/cities',
    '/partners',
    '/partner-settings',
    '/users',
    '/favorites',
    '/users/favorites',
    '/profiles',
    '/sessions',
    '/changes',
    '/point-categories',
    '/product-categories',
    '/promo-codes',
    '/reviews',
    '/products',
    '/orders',
    '/order-actions',
    '/order-history',
    '/partner-statistics',
    '/action-logs',
    '/error-logs',
    '/cache',
    '/notifications',
    '/payment-transactions',
    '/swagger',
    '/health',
  ];

  /// Префиксы маршрутов (куда монтируются контроллеры). Без ведущего слэша.
  static const List<String> routePrefixes = [
    'points',
    'cities',
    'partners',
    'partner-settings',
    'users',
    'favorites',
    'profiles',
    'sessions',
    'changes',
    'point-categories',
    'product-categories',
    'promo-codes',
    'reviews',
    'products',
    'orders',
    'order-actions',
    'order-history',
    'partner-statistics',
    'action-logs',
    'error-logs',
    'cache',
    'notifications',
    'payment-transactions',
    'swagger',
  ];

  /// Правила RBAC: префикс пути (как в request.url.path, БЕЗ ведущего слэша) -> роли с доступом.
  static const Map<String, Set<String>> rbacRoleRules = {
    'action-logs': {'admin'},
    'error-logs': {'admin'},
    'cache': {'admin'},
    'partner-statistics': {'admin', 'support'},
    'promo-codes': {'admin', 'support'},
    'product-categories': {'admin', 'support'},
    'point-categories': {'admin', 'support'},
  };
}
