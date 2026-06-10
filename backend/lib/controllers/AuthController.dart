import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/AuthService.dart';
import '../services/VKAuthHandler.dart' as vk_auth;
import '../repositories/UserRepository.dart';
import '../repositories/UserSessionRepository.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/AuthUtils.dart';
import '../model/entities/UserSessions.dart';
import '../model/dto/requests/CreateUserDto.dart';
import '../model/dto/requests/LoginDto.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/AppException.dart';
import '../middleware/SecurityMiddleware.dart';
import '../utils/RequestBodyUtils.dart';

class AuthController {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserSessionRepository _userSessionRepository;

  AuthController(
    this._authService,
    this._userRepository,
    this._userSessionRepository,
  );

  Router get router {
    final router = Router();

    router.post('/auth/google', _google);
    router.post('/auth/vk', _vk);
    router.post('/auth/register', _register);
    router.post('/auth/refresh', _refreshToken);
    router.post('/login', _login);
    router.post('/auth/check_user', _checkUser);
    router.post('/logout', _logout);

    return router;
  }

  Future<Response> _google(Request request) async {
    try {
      final data = await RequestBodyUtils.readJsonObject(request);

      if (data['idToken'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Отсутствует idToken от Google',
            code: ErrorCode.badRequest,
            headers: _getCorsHeaders());
      }

      try {
        final decodedToken = JwtDecoder.decode(data['idToken'] as String);
        final clientId = Platform.environment['GOOGLE_CLIENT_ID'];
        final clientSecret = Platform.environment['GOOGLE_CLIENT_SECRET'];

        if (clientId == null || clientSecret == null) {
          throw const BadRequestException(
              'Отсутствуют учетные данные Google OAuth2');
        }

        if (decodedToken['iss'] != 'https://accounts.google.com' ||
            decodedToken['aud'] != clientId) {
          return ErrorResponseUtils.errorResponseWithMessage(
              'Недействительный Google ID токен',
              code: ErrorCode.unauthorized,
              headers: _getCorsHeaders());
        }
      } catch (e) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Ошибка проверки Google ID токена',
            code: ErrorCode.unauthorized,
            headers: _getCorsHeaders());
      }

      final user = await _userRepository.findByEmail(data['email'] as String);

      if (user != null) {
        final bundle = AuthUtils.generateTokenBundle(
            user.id, user.role.name.toLowerCase());
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

        final tokens = {
          'access_token': bundle['access_token'],
          'refresh_token': bundle['refresh_token'],
        };
        return Response.ok(
          jsonEncode({
            ...tokens,
            'user': {
              'email': user.email,
              'username': user.username,
              'role': user.role.name.toLowerCase(),
            },
          }),
          headers: _getCorsHeaders(),
        );
      } else {
        return Response(
          404,
          body: jsonEncode({
            'needsRegistration': true,
            'email': data['email'],
            'displayName': data['displayName'],
          }),
          headers: _getCorsHeaders(),
        );
      }
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _vk(Request request) {
    return vk_auth.handleVkAuth(
        request, _userRepository, _userSessionRepository);
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
            headers: _getCorsHeaders());
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
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Future<Response> _register(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      try {
        final data = await RequestBodyUtils.readJsonObject(request);
        // Прогоняем DTO-валидацию, но в сервис передаём исходные данные,
        // чтобы сохранить поля password_confirm и number для UserValidationUtils.
        CreateUserDto.fromJson(data);

        final result = await _authService.register(
          data,
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: SecurityMiddleware.extractClientIp(request),
        );

        final response = Response.ok(
          jsonEncode(result),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          '[REDACTED]',
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e,
            requestId: RequestContextUtils.getRequestId(request),
            headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка регистрации', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _login(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      try {
        final data = await RequestBodyUtils.readJsonObject(request);

        final loginDto = LoginDto.fromJson(data);

        final result = await _authService.login(
          loginDto.username,
          loginDto.password,
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: SecurityMiddleware.extractClientIp(request),
        );

        final response = Response.ok(
          jsonEncode(result),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          '[REDACTED]',
          requestId: RequestContextUtils.getRequestId(request),
        );

        return response;
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e,
            requestId: RequestContextUtils.getRequestId(request),
            headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка входа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _refreshToken(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final data = await RequestBodyUtils.readJsonObject(request);
      final result =
          await _authService.refreshToken(data['refresh_token'] as String);

      final response = Response.ok(
        jsonEncode(result),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        '[REDACTED]',
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления токена', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      final payload = RequestContextUtils.getUser(request);
      if (payload == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Требуется авторизация',
            code: ErrorCode.unauthorized,
            headers: _getCorsHeaders());
      }
      final refreshJti = payload['rtj']?.toString() ?? '';
      if (refreshJti.isEmpty) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Недействительный токен',
            code: ErrorCode.unauthorized,
            headers: _getCorsHeaders());
      }
      final refreshJtiHash = AuthUtils.hashRefreshJti(refreshJti);
      await _userSessionRepository.revokeByRefreshJtiHash(refreshJtiHash);
      return Response.ok(jsonEncode({'message': 'Выход выполнен'}),
          headers: _getCorsHeaders());
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
