import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/database/database.dart';
import 'package:backend/services/AuthService.dart';
import 'package:backend/repositories/UserRepository.dart';


void main() async {
  try {
    final db = await Database.instance;
    final userRepository = UserRepository(db.connection);
    final authService = AuthService(userRepository);

    final app = Router();

    final corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, PATCH, DELETE',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Content-Type': 'application/json',
    };

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware((innerHandler) {
          return (request) async {
            if (request.method == 'OPTIONS') {
              return Response.ok('', headers: corsHeaders);
            }
            final response = await innerHandler(request);
            return response.change(headers: {...response.headers, ...corsHeaders});
          };
        })
        .addHandler(app);

    app.post('/register', (Request request) async {
      try {
        print('Получен запрос на регистрацию');
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await authService.register(data);
        
        return Response.ok(jsonEncode(result));
      } catch (e) {
        print('Ошибка регистрации: $e');
        return Response(400, body: jsonEncode({'error': e.toString()}));
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

    final server = await io.serve(handler, '0.0.0.0', 3000);
    print('Сервер запущен на http://0.0.0.0:3000');
  } catch (e, stackTrace) {
    print('Ошибка запуска сервера: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}