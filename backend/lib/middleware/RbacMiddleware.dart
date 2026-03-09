import 'package:shelf/shelf.dart';

/// Примитивный RBAC / owner helper поверх уже проверенного JWT.
/// SecurityMiddleware.checkJWT кладёт payload токена в request.context['user'].
class RbacMiddleware {
  /// Централизованная проверка ролей по префиксам маршрутов.
  ///
  /// [rules] — карта: префикс пути -> множество разрешённых ролей (в нижнем регистре).
  /// Пример: { 'products': {'admin'}, 'error-logs': {'admin', 'support'} }.
  static Middleware withRoleRules(Map<String, Set<String>> rules) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;

        // Находим первое подходящее правило по префиксу.
        Set<String>? allowedRoles;
        for (final entry in rules.entries) {
          if (path.startsWith(entry.key)) {
            allowedRoles = entry.value;
            break;
          }
        }

        // Если для пути нет правил — пропускаем без доп. проверок.
        if (allowedRoles == null) {
          return innerHandler(request);
        }

        final payload = request.context['user'] as Map<String, dynamic>?;
        final role = payload?['role']?.toString().toLowerCase();

        if (role == null) {
          return Response.forbidden('Требуется аутентификация для доступа к этому ресурсу');
        }

        if (!allowedRoles.contains(role)) {
          return Response.forbidden('Недостаточно прав для доступа к этому ресурсу');
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
    final payload = request.context['user'] as Map<String, dynamic>?;
    if (payload == null) return false;

    final userId = payload['id'];
    final role = payload['role']?.toString().toLowerCase();

    if (userId is int && userId == ownerId) return true;
    if (role != null && elevatedRoles.contains(role)) return true;
    return false;
  }
}

