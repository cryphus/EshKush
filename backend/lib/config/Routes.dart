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
    'payments',
    'swagger',
  ];

  /// Правила RBAC: префикс пути -> {HTTP-метод -> роли}.
  /// '*' = все методы; пустое множество ролей = разрешено любому аутентифицированному.
  static const Set<String> authenticatedRoles = {
    'user',
    'partner',
    'support',
    'admin',
  };

  static const Map<String, Map<String, Set<String>>> rbacRoleRules = {
    'users':                {'*': authenticatedRoles},
    'profiles':             {'*': authenticatedRoles},
    'sessions':             {'*': authenticatedRoles},
    'favorites':            {'*': authenticatedRoles},
    'notifications':        {'*': authenticatedRoles},
    'orders':               {'*': authenticatedRoles},
    'order-actions':        {'*': authenticatedRoles},
    'order-history':        {'*': authenticatedRoles},
    'payment-transactions': {'*': authenticatedRoles},
    'payments':             {'*': authenticatedRoles},

    'points':               {'*': authenticatedRoles},
    'cities':               {'*': authenticatedRoles},
    'products':             {'*': authenticatedRoles},
    'reviews':              {'*': authenticatedRoles},
    'partners':             {'*': authenticatedRoles},
    'partner-settings':     {'*': authenticatedRoles},

    'action-logs':          {'*': {'admin'}},
    'error-logs':           {'*': {'admin'}},
    'cache':                {'*': {'admin'}},
    'changes':              {'*': {'admin', 'support'}},

    'partner-statistics':   {'GET': {'admin', 'support', 'partner'}, '*': {'admin', 'support'}},
    'promo-codes':          {'GET': authenticatedRoles, '*': {'admin', 'support'}},
    'product-categories':   {'GET': authenticatedRoles, '*': {'admin', 'support'}},
    'point-categories':     {'GET': authenticatedRoles, '*': {'admin', 'support'}},
  };
}
