import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/database/Database.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';
import 'package:backend/utils/AuthUtils.dart';
import 'package:backend/controllers/SwaggerController.dart';
import 'package:path/path.dart' as p;

void main() async {
  try {
    final db = await Database.instance;
    final userRepository = UserRepository(db.connection);
    final authService = AuthService(userRepository);
    final swaggerController = SwaggerController();

    final app = Router();

    final corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, PATCH, DELETE',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With, Accept, Access-Control-Allow-Origin',
      'Access-Control-Allow-Credentials': 'true',
      'Content-Type': 'application/json',
    };

    Middleware corsMiddleware = (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }

        final response = await innerHandler(request);
        return response.change(headers: {...response.headers, ...corsHeaders});
      };
    };

    app.post('/auth/google', (Request request) async {
      try {
        print('Получен запрос на аутентификацию через Google');
        final body = await request.readAsString();
        print('Тело запроса: $body');
        final data = jsonDecode(body);
        print('Данные запроса: $data');
        
        final user = await userRepository.findByEmail(data['email']);
        print('Найденный пользователь: $user');
        
        if (user != null) {
          final tokens = AuthUtils.generateTokens(user.id, user.role.name.toLowerCase());
          return Response.ok(
            jsonEncode({
              ...tokens,
              'user': {
                'email': user.email,
                'username': user.username,
                'role': user.role.name.toLowerCase(),
              }
            }),
            headers: corsHeaders,
          );
        } else {
          return Response(
            404,
            body: jsonEncode({
              'needsRegistration': true,
              'email': data['email'],
              'displayName': data['displayName'],
            }),
            headers: corsHeaders,
          );
        }
      } catch (e) {
        print('Ошибка аутентификации через Google: $e');
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
          headers: corsHeaders,
        );
      }
    });

    app.post('/auth/register', (Request request) async {
      try {
        print('Получен запрос на регистрацию');
        final body = await request.readAsString();
        final data = jsonDecode(body);
        print('Данные регистрации: $data');
        
        final result = await authService.register(data);
        
        return Response.ok(
          jsonEncode(result),
          headers: corsHeaders,
        );
      } catch (e) {
        print('Ошибка регистрации: $e');
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
          headers: corsHeaders,
        );
      }
    });

    app.post('/auth/refresh', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        if (data['refresh_token'] == null) {
          return Response(400, body: jsonEncode({'error': 'Требуется refresh_token'}));
        }

        final result = await authService.refreshToken(data['refresh_token']);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response(401, body: jsonEncode({'error': e.toString()}));
      }
    });

    app.post('/login', (Request request) async {
      try {
        final data = jsonDecode(await request.readAsString());
        final result = await authService.login(
          data['username'],
          data['password'],
        );
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response(401, body: jsonEncode({'error': e.toString()}));
      }
    });

    app.post('/auth/check_user', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final phoneNumber = data['phoneNumber'] as String;
        
        final user = await userRepository.queryOne(
          'SELECT * FROM users WHERE number = @number',
          params: {'number': phoneNumber},
        );
        
        return Response.ok(
          jsonEncode({
            'exists': user != null,
            'user': user
          }),
          headers: corsHeaders,
        );
      } catch (e) {
        print('Ошибка проверки пользователя: $e');
        return Response(
          400,
          body: jsonEncode({'error': e.toString()}),
          headers: corsHeaders,
        );
      }
    });

    // Добавляем маршруты Swagger
    app.mount('/swagger', swaggerController.handler);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware)
        .addHandler(app.call);

    final server = await io.serve(handler, '0.0.0.0', 8080);
    print('Сервер запущен на http://0.0.0.0:8080');
  } catch (e, stackTrace) {
    print('Ошибка запуска сервера: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
