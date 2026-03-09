import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/AuthService.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/requests/CreateUserDto.dart';
import '../model/dto/requests/LoginDto.dart';
import '../utils/ValidationUtils.dart';
import '../utils/ErrorResponseUtils.dart';

class AuthController {
  final AuthService _authService;

  AuthController(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refreshToken);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      try {
        final data = jsonDecode(body);

        final createDto = CreateUserDto.fromJson(data);

        final result = await _authService.register(
          createDto.toEntityData(),
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка регистрации', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      try {
        final data = jsonDecode(body);

        final loginDto = LoginDto.fromJson(data);

        final result = await _authService.login(
          loginDto.username,
          loginDto.password,
          userAgent: request.headers['user-agent'] ?? 'unknown',
          ipAddress: request.headers['x-forwarded-for'] ?? request.headers['x-real-ip'] ?? 'unknown',
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
        return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка входа', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _refreshToken(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final data = jsonDecode(body);
      final result = await _authService.refreshToken(data['refresh_token'] as String);

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
      await LoggingUtils.logError('Ошибка обновления токена', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
