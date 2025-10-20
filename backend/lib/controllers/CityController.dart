import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/CityService.dart';
import '../model/entities/City.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class CityController {
  final CityService _service;

  CityController(this._service);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      try {
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
        final cities = await _service.getAll();
        final body = jsonEncode(cities.map((c) => c.toJson()).toList());
        final resp = Response.ok(body, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } catch (e) {
        await LoggingUtils.logError('Ошибка получения городов', e, requestId: RequestContextUtils.getRequestId(request));
        return Response.internalServerError(body: jsonEncode({'error': 'Ошибка получения городов: $e'}), headers: _getCorsHeaders());
      }
    });

    router.get('/<id>', (Request request, String id) async {
      try {
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
        final city = await _service.getById(int.parse(id));
        if (city == null) {
          return Response.notFound(
            jsonEncode({'error': 'Город не найден'}),
            headers: _getCorsHeaders(),
          );
        }
        final body = jsonEncode(city.toJson());
        final resp = Response.ok(body, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } catch (e) {
        await LoggingUtils.logError('Ошибка получения города', e, requestId: RequestContextUtils.getRequestId(request));
        return Response.internalServerError(body: jsonEncode({'error': 'Ошибка получения города: $e'}), headers: _getCorsHeaders());
      }
    });

    router.post('/', (Request request) async {
      try {
        final body = await request.readAsString();
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
        
        // Декодируем тело запроса с учетом кодировки
        final bytes = utf8.encode(body);
        final decodedBody = utf8.decode(bytes);
        final json = jsonDecode(decodedBody) as Map<String, dynamic>;
        
        final city = City.fromJson(json);
        
        final created = await _service.create(city);
        final out = jsonEncode(created.toJson());
        final resp = Response.ok(out, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } catch (e) {
        await LoggingUtils.logError('Ошибка создания города', e, requestId: RequestContextUtils.getRequestId(request));
        return Response.internalServerError(body: jsonEncode({'error': 'Ошибка создания города: $e'}), headers: _getCorsHeaders());
      }
    });

    router.put('/<id>', (Request request, String id) async {
      try {
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
        final body = await request.readAsString();
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
        final json = jsonDecode(body) as Map<String, dynamic>;
        json['id'] = int.parse(id);
        final city = City.fromJson(json);
        final updated = await _service.update(city);
        final out = jsonEncode(updated.toJson());
        final resp = Response.ok(out, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } catch (e) {
        await LoggingUtils.logError('Ошибка обновления города', e, requestId: RequestContextUtils.getRequestId(request));
        return Response.internalServerError(body: jsonEncode({'error': 'Ошибка обновления города: $e'}), headers: _getCorsHeaders());
      }
    });

    router.delete('/<id>', (Request request, String id) async {
      try {
        await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
        await _service.delete(int.parse(id));
        final body = jsonEncode({'message': 'Город успешно удален'});
        final resp = Response.ok(body, headers: _getCorsHeaders());
        await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
        return resp;
      } catch (e) {
        await LoggingUtils.logError('Ошибка удаления города', e, requestId: RequestContextUtils.getRequestId(request));
        return Response.internalServerError(body: jsonEncode({'error': 'Ошибка удаления города: $e'}), headers: _getCorsHeaders());
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