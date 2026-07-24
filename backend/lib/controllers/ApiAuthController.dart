import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware/SecurityMiddleware.dart';
import '../model/dto/requests/LoginDto.dart';
import '../model/entities/UserSessions.dart';
import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../services/AuthService.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestBodyUtils.dart';

class ApiAuthController {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserSessionRepository _userSessionRepository;

  ApiAuthController(
    this._authService,
    this._userRepository,
    this._userSessionRepository,
  );

  Router get router {
    final router = Router();
    router.post('/auth/google', _googleDisabled);
    router.post('/auth/register', _register);
    router.post('/auth/refresh', _refresh);
    router.post('/login', _login);
    router.post('/auth/check_user', _checkUser);
    router.post('/auth/telegram', _telegram);
    router.post('/logout', _logout);
    return router;
  }

  Future<Response> _googleDisabled(Request request) async {
    return ErrorResponseUtils.errorResponseWithMessage(
      'Google OAuth disabled. Use Yandex/VK.',
      code: ErrorCode.badRequest,
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _register(Request request) async {
    try {
      final data = await RequestBodyUtils.readJsonObject(request);
      final result = await _authService.register(
        data,
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: SecurityMiddleware.extractClientIp(request),
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _refresh(Request request) async {
    try {
      final data = await RequestBodyUtils.readJsonObject(request);

      if (data['refresh_token'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется refresh_token',
          code: ErrorCode.badRequest,
          headers: {'content-type': 'application/json'},
        );
      }

      final result = await _authService.refreshToken(data['refresh_token']);
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final data = await RequestBodyUtils.readJsonObject(request);
      final loginDto = LoginDto.fromJson(data);
      final result = await _authService.login(
        loginDto.username,
        loginDto.password,
        userAgent: request.headers['user-agent'] ?? 'unknown',
        ipAddress: SecurityMiddleware.extractClientIp(request),
      );

      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _checkUser(Request request) async {
    try {
      final data = await RequestBodyUtils.readJsonObject(request);
      final phoneNumber =
          (data['phoneNumber'] ?? data['phone_number'] ?? data['number'])
              ?.toString();

      if (phoneNumber == null || phoneNumber.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется номер телефона',
          code: ErrorCode.badRequest,
          headers: {'content-type': 'application/json'},
        );
      }

      final user = await _userRepository.queryOne(
        '''
        SELECT 
          id,
          username,
          password,
          email,
          number,
          role,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          CASE 
            WHEN updated_at IS NOT NULL THEN to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
            ELSE NULL
          END as updated_at
        FROM users 
        WHERE number = @number
        ''',
        params: {'number': phoneNumber},
      );

      return Response.ok(
        jsonEncode({'exists': user != null}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// Логин по номеру телефона, подтверждённому Telegram-ботом.
  ///
  /// Вызывается только сервисом telegramAuth (не публичный клиентский
  /// эндпоинт): номер телефона приходит из Telegram Contact API, поэтому
  /// его можно считать проверенным без пароля, но только если запрос
  /// аутентифицирован общим секретом между сервисами.
  Future<Response> _telegram(Request request) async {
    try {
      final expectedSecret = Platform.environment['TELEGRAM_SERVICE_SECRET'];
      final providedSecret = request.headers['x-telegram-service-secret'];
      if (expectedSecret == null ||
          expectedSecret.isEmpty ||
          providedSecret != expectedSecret) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Недействительный сервисный секрет',
          code: ErrorCode.unauthorized,
          headers: {'content-type': 'application/json'},
        );
      }

      final data = await RequestBodyUtils.readJsonObject(request);
      final phoneNumber = data['phoneNumber']?.toString();
      final firstName = data['firstName']?.toString() ?? '';
      final lastName = data['lastName']?.toString() ?? '';
      if (phoneNumber == null || phoneNumber.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется номер телефона',
          code: ErrorCode.badRequest,
          headers: {'content-type': 'application/json'},
        );
      }

      final user = await _userRepository.findByNumber(phoneNumber);

      if (user == null) {
        return Response.ok(
          jsonEncode({
            'exists': false,
            'phoneNumber': phoneNumber,
            'firstName': firstName,
            'lastName': lastName,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final bundle =
          AuthUtils.generateTokenBundle(user.id, user.role.name.toLowerCase());
      final refreshJti = bundle['refresh_jti'] as String;
      final refreshExpiresAt = bundle['refresh_expires_at'] as DateTime;

      await _userSessionRepository.create(
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
          'exists': true,
          'access_token': bundle['access_token'],
          'refresh_token': bundle['refresh_token'],
          'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'number': user.number,
            'role': user.role.name.toLowerCase(),
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      final context = request.context['user'] as Map<String, dynamic>?;
      if (context == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Требуется авторизация',
          code: ErrorCode.unauthorized,
          headers: {'content-type': 'application/json'},
        );
      }

      final refreshJti = context['rtj']?.toString() ?? '';
      if (refreshJti.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
          'Недействительный токен',
          code: ErrorCode.unauthorized,
          headers: {'content-type': 'application/json'},
        );
      }

      final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
      await _userSessionRepository.revokeByRefreshJtiHash(refreshJtiHash);
      return Response.ok(
        jsonEncode({'message': 'Выход выполнен'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(
        e,
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
