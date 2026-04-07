import 'package:shelf/shelf.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';

/// Примитивный RBAC / owner helper поверх уже проверенного JWT.
/// Payload берётся через RequestContextUtils.getUser (кладёт SecurityMiddleware.checkJWT).
class RbacMiddleware {
  /// Централизованная проверка ролей по префиксам маршрутов с учётом HTTP-метода.
  ///
  /// [rules] — карта: префикс пути -> {метод -> роли}.
  /// Ключ метода: конкретный HTTP-метод ('GET', 'POST', ...) или '*' для всех.
  /// Пустое множество ролей ({}) = разрешено любому аутентифицированному пользователю.
  /// Пример: { 'error-logs': {'*': {'admin'}}, 'promo-codes': {'GET': {}, '*': {'admin'}} }.
  static Middleware withRoleRules(Map<String, Map<String, Set<String>>> rules) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;
        final method = request.method.toUpperCase();

        // Находим первое подходящее правило по префиксу.
        Map<String, Set<String>>? methodRules;
        for (final entry in rules.entries) {
          if (path.startsWith(entry.key)) {
            methodRules = entry.value;
            break;
          }
        }

        // Если для пути нет правил — пропускаем без доп. проверок.
        if (methodRules == null) {
          return innerHandler(request);
        }

        // Ищем правило для конкретного метода, затем для '*'.
        final allowedRoles = methodRules[method] ?? methodRules['*'];

        // Нет правила для этого метода — пропускаем.
        if (allowedRoles == null) {
          return innerHandler(request);
        }

        // Пустое множество ролей — разрешено всем аутентифицированным.
        if (allowedRoles.isEmpty) {
          return innerHandler(request);
        }

        final payload = RequestContextUtils.getUser(request);
        final role = payload?['role']?.toString().toLowerCase();

        if (role == null) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Требуется аутентификация для доступа к этому ресурсу',
            code: ErrorCode.forbidden,
            headers: {'Content-Type': 'application/json'},
          );
        }

        if (!allowedRoles.contains(role)) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Недостаточно прав для доступа к этому ресурсу',
            code: ErrorCode.forbidden,
            headers: {'Content-Type': 'application/json'},
          );
        }

        return innerHandler(request);
      };
    };
  }

  /// Проверка владения ресурсом: текущий пользователь = [ownerId] или имеет одну
  /// из ролей [elevatedRoles] (по умолчанию admin).
  static bool isOwnerOrElevated(
    Request request,
    int ownerId, {
    Set<String> elevatedRoles = const {'admin'},
  }) {
    final payload = RequestContextUtils.getUser(request);
    if (payload == null) return false;

    final userId = payload['id'];
    final role = payload['role']?.toString().toLowerCase();

    if (userId is int && userId == ownerId) return true;
    if (role != null && elevatedRoles.contains(role)) return true;
    return false;
  }
}

