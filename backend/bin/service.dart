import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // Загружаем .env файл с правильным путем
  final env = DotEnv()..load(['backend/.env']);  // Указываем полный путь к файлу
  
  // Создаем подключение к БД используя переменные из .env
  final connection = PostgreSQLConnection(
    env['DB_HOST'] ?? 'localhost',
    int.parse(env['DB_PORT'] ?? '5432'),
    env['DB_NAME'] ?? 'flutter_auth',
    username: env['DB_USER'] ?? 'postgres',
    password: env['DB_PASSWORD'] ?? 'TQr132123',
  );

  try {
    await connection.open();
    print('БД подключена успешно');
    
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL
      )
    ''');

    final app = Router();

    // Упрощаем CORS
    final handler = Pipeline()
        .addMiddleware((innerHandler) {
          return (request) async {
            if (request.method == 'OPTIONS') {
              return Response.ok('', headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Origin, Content-Type',
              });
            }
            final response = await innerHandler(request);
            return response.change(headers: {
              'Access-Control-Allow-Origin': '*',
            });
          };
        })
        .addHandler(app);

    // Регистрация
    app.post('/register', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      try {
        await connection.execute(
          'INSERT INTO users (username, password) VALUES (@u, @p)',
          substitutionValues: {
            'u': data['username'],
            'p': data['password'],
          },
        );
        return Response.ok('OK');
      } catch (e) {
        return Response(400, body: 'Ошибка регистрации: $e');
      }
    });

    // Вход
    app.post('/login', (Request request) async {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final result = await connection.query(
        'SELECT id FROM users WHERE username=@u AND password=@p',
        substitutionValues: {
          'u': data['username'],
          'p': data['password'],
        },
      );
      
      if (result.isEmpty) {
        return Response(401, body: 'Неверный логин или пароль');
      }
      return Response.ok('OK');
    });

    final server = await io.serve(handler, 'localhost', 3000);
    print('Сервер запущен на http://localhost:3000');
  } catch (e) {
    print('Ошибка: $e');
    exit(1);
  }
}