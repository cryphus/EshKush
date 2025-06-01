import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/CityService.dart';
import '../model/entities/City.dart';

class CityController {
  final CityService _service;

  CityController(this._service);

  Future<Response> getById(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id'] ?? '');
      final city = await _service.getById(id);
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
  }

  Future<Response> getAll(Request request) async {
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
  }

  Future<Response> create(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final city = City.fromJson(json);
      final created = await _service.create(city);
      return Response.ok(
        jsonEncode(created.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Ошибка создания города: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> update(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
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
  }

  Future<Response> delete(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id'] ?? '');
      await _service.delete(id);
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