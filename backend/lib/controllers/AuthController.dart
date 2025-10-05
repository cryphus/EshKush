import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/AuthService.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

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
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final data = jsonDecode(body);
      final result = await _authService.register(data);

      final response = Response.ok(
        jsonEncode(result),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(result),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка регистрации', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(
        400,
        body: jsonEncode({'error': e.toString()}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final data = jsonDecode(body);
      final result = await _authService.login(
        data['username'] as String,
        data['password'] as String,
      );

      final response = Response.ok(
        jsonEncode(result),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        jsonEncode(result),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка входа', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(
        400,
        body: jsonEncode({'error': e.toString()}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _refreshToken(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
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
        jsonEncode(result),
        requestId: RequestContextUtils.getRequestId(request),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления токена', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(
        400,
        body: jsonEncode({'error': e.toString()}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
    };
  }
} 