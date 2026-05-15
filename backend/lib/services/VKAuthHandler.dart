import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../repositories/UserRepository.dart';
import '../utils/ErrorResponseUtils.dart';
import '../repositories/UserSessionRepository.dart';
import '../utils/AuthUtils.dart';
import '../model/entities/UserSessions.dart';
import '../middleware/SecurityMiddleware.dart';

/// Обработчик VK-авторизации. Не привязан к маршрутизации,
/// чтобы вызываться из Service.dart.
Future<Response> handleVkAuth(
  Request request,
  UserRepository userRepository,
  UserSessionRepository userSessionRepository,
) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    // Берём VK ID из username или id
    final rawId = data['username']?.toString() ?? data['id']?.toString();
    if (rawId == null || rawId.isEmpty) {
      return ErrorResponseUtils.errorResponseWithMessage(
        'Отсутствует идентификатор пользователя VK (username/id)',
        code: ErrorCode.badRequest,
        headers: {'Content-Type': 'application/json'},
      );
    }

    final vkUsername = 'vk_$rawId';
    final email = (data['email']?.toString() ?? '').trim().isNotEmpty
        ? data['email'].toString()
        : '$rawId@vk.com';

    // Ищем пользователя сначала по email, затем по vkUsername
    var user = email.isNotEmpty ? await userRepository.findByEmail(email) : null;
    user ??= await userRepository.findByUsername(vkUsername);

    if (user == null) {
      // Создаём пользователя. Пароль нужен только для прохождения валидации.
      final generatedPassword = 'Vk_${rawId}_Aa1!';
      const fallbackPhone = '+79000000000';

      final createData = <String, dynamic>{
        'username': vkUsername,
        'password': generatedPassword,
        'password_confirm': generatedPassword,
        'email': email,
        'number': (data['phone']?.toString().trim().isNotEmpty ?? false)
            ? data['phone'].toString()
            : fallbackPhone,
        'role': 'user',
      };

      user = await userRepository.createUser(createData);
    }

    final bundle = AuthUtils.generateTokenBundle(
      user.id,
      user.role.name.toLowerCase(),
    );
    final refreshJti = bundle['refresh_jti'] as String;
    final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

    await userSessionRepository.create(
      UserSessions(
        id: 0,
        userId: user.id,
        createdAt: DateTime.now(),
        expiresAt: refreshExpiresAt,
        lastActive: DateTime.now(),
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: SecurityMiddleware.extractClientIp(request),
        token: bundle['access_token'] as String,
        refreshJtiHash: AuthUtils.hashRefreshJti(refreshJti),
      ),
    );

    return Response.ok(
      jsonEncode({
        'access_token': bundle['access_token'],
        'refresh_token': bundle['refresh_token'],
        'user': {
          'id': user.id,
          'email': user.email,
          'username': user.username,
          'role': user.role.name.toLowerCase(),
        },
      }),
    );
  } catch (e) {
    return ErrorResponseUtils.errorResponse(
      e,
      headers: {'Content-Type': 'application/json'},
    );
  }
}
