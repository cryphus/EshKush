import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/CityService.dart';
import '../model/entities/City.dart';

class CityController {
  final CityService _service;

  CityController(this._service);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      try {
        final cities = await _service.getAll();
        return Response.ok(
          jsonEncode(cities.map((c) => c.toJson()).toList()),
          headers: _getCorsHeaders(),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Ошибка получения городов: $e'}),
          headers: _getCorsHeaders(),
        );
      }
    });

    router.get('/<id>', (Request request, String id) async {
      try {
        final city = await _service.getById(int.parse(id));
        if (city == null) {
          return Response.notFound(
            jsonEncode({'error': 'Город не найден'}),
            headers: _getCorsHeaders(),
          );
        }
        return Response.ok(
          jsonEncode(city.toJson()),
          headers: _getCorsHeaders(),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Ошибка получения города: $e'}),
          headers: _getCorsHeaders(),
        );
      }
    });

    router.post('/', (Request request) async {
      try {
        final body = await request.readAsString();
        print('Получен запрос на создание города: $body');
        
        // Декодируем тело запроса с учетом кодировки
        final bytes = utf8.encode(body);
        final decodedBody = utf8.decode(bytes);
        final json = jsonDecode(decodedBody) as Map<String, dynamic>;
        print('Декодированный JSON: $json');
        
        final city = City.fromJson(json);
        print('Создан объект города: $city');
        
        final created = await _service.create(city);
        print('Город успешно создан: $created');
        
        return Response.ok(
          jsonEncode(created.toJson()),
          headers: _getCorsHeaders(),
        );
      } catch (e, stackTrace) {
        print('Ошибка создания города: $e');
        print('Stack trace: $stackTrace');
        return Response.internalServerError(
          body: jsonEncode({'error': 'Ошибка создания города: $e'}),
          headers: _getCorsHeaders(),
        );
      }
    });

    router.put('/<id>', (Request request, String id) async {
      try {
        final body = await request.readAsString();
        final json = jsonDecode(body) as Map<String, dynamic>;
        json['id'] = int.parse(id);
        final city = City.fromJson(json);
        final updated = await _service.update(city);
        return Response.ok(
          jsonEncode(updated.toJson()),
          headers: _getCorsHeaders(),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Ошибка обновления города: $e'}),
          headers: _getCorsHeaders(),
        );
      }
    });

    router.delete('/<id>', (Request request, String id) async {
      try {
        await _service.delete(int.parse(id));
        return Response.ok(
          jsonEncode({'message': 'Город успешно удален'}),
          headers: _getCorsHeaders(),
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Ошибка удаления города: $e'}),
          headers: _getCorsHeaders(),
        );
      }
    });

    return router;
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