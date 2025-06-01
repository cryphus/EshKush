import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main() async {
  // Создаем обработчик для статических файлов
  final staticHandler = createStaticHandler(
    '.',
    defaultDocument: 'Swagger.html',
    listDirectories: true,
  );

  // Создаем обработчик для CORS
  final corsHandler = createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        });
      }
      return null;
    },
  );

  // Создаем обработчик для API документации
  final apiHandler = (Request request) async {
    if (request.url.path == 'swagger.json') {
      final file = File('backend/lib/config/swagger.json');
      if (await file.exists()) {
        return Response.ok(
          await file.readAsString(),
          headers: {'content-type': 'application/json'},
        );
      }
    }
    return Response.notFound('Not found');
  };

  // Объединяем все обработчики
  final handler = const Pipeline()
      .addMiddleware(corsHandler)
      .addMiddleware(logRequests())
      .addHandler(Cascade()
          .add(apiHandler)
          .add(staticHandler)
          .handler);

  // Запускаем сервер
  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Сервер запущен на http://localhost:${server.port}');
} 