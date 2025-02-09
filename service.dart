import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart'; 
import 'package:dotenv/dotenv.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

final env = DotEnv()..load();

final connection = PostgreSQLConnection(
  env['DB_HOST']!,
  int.parse(env['DB_PORT']!),
  env['DB_NAME']!,
  username: env['DB_USER']!,
  password: env['DB_PASSWORD']!,
);



void main() async {
  await connection.open();

  final app = Router();

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(app);

  app.post('/register', _registerHandler);
  app.post('/login', _loginHandler);

  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server running on ${server.address.host}:${server.port}');
}

Future<Response> _registerHandler(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final username = data['username'];
  final password = data['password'];

  try {
    await connection.query(
      'INSERT INTO users (username, password) VALUES (@username, @password)',
      substitutionValues: {
        'username': username,
        'password': password,
      },
    );
    return Response.ok('User registered successfully');
  } catch (e) {
    return Response.internalServerError(body: 'Error: $e');
  }
}

Future<Response> _loginHandler(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final username = data['username'];
  final password = data['password'];

  final result = await connection.query(
    'SELECT * FROM users WHERE username = @username AND password = @password',
    substitutionValues: {
      'username': username,
      'password': password,
    },
  );

  if (result.isEmpty) {
    return Response.unauthorized('Invalid credentials');
  }

  return Response.ok('Login successful');
}