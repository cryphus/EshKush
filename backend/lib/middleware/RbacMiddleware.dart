import 'package:shelf/shelf.dart';

import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestContextUtils.dart';

class RbacMiddleware {
  static Middleware withRoleRules(
    Map<String, Map<String, Set<String>>> rules, {
    List<String> openPathPrefixes = const [],
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        final path = request.url.path;
        final method = request.method.toUpperCase();
        if (openPathPrefixes.any((p) => _matchesPathPrefixSegment(path, p))) {
          return innerHandler(request);
        }

        Map<String, Set<String>>? methodRules;
        var matchedPrefixLength = -1;
        for (final entry in rules.entries) {
          if (_matchesPathPrefixSegment(path, entry.key) &&
              entry.key.length > matchedPrefixLength) {
            methodRules = entry.value;
            matchedPrefixLength = entry.key.length;
          }
        }

        if (methodRules == null) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Доступ к маршруту запрещён',
            code: ErrorCode.forbidden,
            headers: {'Content-Type': 'application/json'},
          );
        }

        final allowedRoles = methodRules[method] ?? methodRules['*'];
        if (allowedRoles == null) {
          return ErrorResponseUtils.errorResponseWithMessage(
            'Метод запрещён для этого маршрута',
            code: ErrorCode.forbidden,
            headers: {'Content-Type': 'application/json'},
          );
        }

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

  static bool _matchesPathPrefixSegment(String path, String prefix) {
    if (prefix.isEmpty) return path.isEmpty;
    return path == prefix || path.startsWith('$prefix/');
  }
}
