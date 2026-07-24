import 'package:shelf/shelf.dart';
import 'ErrorResponseUtils.dart';

class RequestContextUtils {
  static String? getRequestId(Request request) {
    final value = request.context['requestId'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  /// Payload JWT из context (кладёт SecurityMiddleware.checkJWT). null, если пользователь не авторизован.
  static Map<String, dynamic>? getUser(Request request) {
    final value = request.context['user'];
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  /// Возвращает 401 Response в формате ErrorResponseUtils, если пользователя нет в context. Иначе null.
  static Response? requireUserOr401(Request request, {Map<String, String>? headers}) {
    if (getUser(request) != null) return null;
    return ErrorResponseUtils.errorResponseWithMessage(
      'Требуется авторизация',
      code: ErrorCode.unauthorized,
      headers: headers ?? {'Content-Type': 'application/json'},
    );
  }

  /// ID аутентифицированного пользователя из JWT payload. null если не авторизован.
  static int? getUserId(Request request) {
    final id = getUser(request)?['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  /// Роль аутентифицированного пользователя в нижнем регистре. null если не авторизован.
  static String? getRole(Request request) =>
      getUser(request)?['role']?.toString().toLowerCase();

  /// Возвращает true если аутентифицированный пользователь имеет роль [role] (case-insensitive).
  static bool hasRole(Request request, String role) =>
      getRole(request) == role.toLowerCase();

  /// Возвращает true если аутентифицированный пользователь — администратор.
  ///
  /// Единственное место в коде, где знают, что означает «admin».
  /// Все контроллеры должны использовать этот метод вместо payload['role'] == 'admin'.
  static bool isAdmin(Request request) => hasRole(request, 'admin');

  /// Возвращает true если пользователь — партнёр или администратор.
  ///
  /// Используется для операций управления собственным контентом партнёра
  /// (создание/редактирование точек и продуктов), которые по RBAC-модели
  /// доступны роли partner и выше (см. FR-05 и таблицу маршрутов API).
  static bool isPartnerOrAdmin(Request request) =>
      hasRole(request, 'partner') || hasRole(request, 'admin');
}


