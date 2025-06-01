import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PartnerStatisticsService.dart';
import '../utils/AuthUtils.dart';

class PartnerStatisticsController {
  final PartnerStatisticsService _statisticsService;

  PartnerStatisticsController(this._statisticsService);

  Future<Response> getStatistics(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsById(id);
      return Response.ok(
        jsonEncode(statistics.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка получения статистики: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getPartnerStatistics(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final partnerId = int.tryParse(request.url.queryParameters['partner_id'] ?? '');
      
      if (partnerId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID партнера'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPartnerId(partnerId);
      return Response.ok(
        jsonEncode(statistics.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка получения статистики партнера: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getPointStatistics(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final pointId = int.tryParse(request.url.queryParameters['point_id'] ?? '');
      
      if (pointId == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID точки'}),
          headers: _getCorsHeaders(),
        );
      }

      final statistics = await _statisticsService.getStatisticsByPointId(pointId);
      return Response.ok(
        jsonEncode(statistics.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка получения статистики точки: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createStatistics(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      final statistics = await _statisticsService.createStatistics(data);
      return Response.ok(
        jsonEncode(statistics.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка создания статистики: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateStatistics(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректный ID'}),
          headers: _getCorsHeaders(),
        );
      }

      final data = jsonDecode(await request.readAsString());
      final statistics = await _statisticsService.updateStatistics(id, data);
      
      return Response.ok(
        jsonEncode(statistics.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка обновления статистики: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> addOrder(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['id'] == null || data['revenue'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addOrder(data['id'], data['revenue'].toDouble());
      return Response.ok(
        jsonEncode({'message': 'Заказ добавлен в статистику'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка добавления заказа: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> addCancel(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствует ID статистики'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.addCancel(data['id']);
      return Response.ok(
        jsonEncode({'message': 'Отмена добавлена в статистику'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка добавления отмены: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updateRating(Request request) async {
    try {
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(await request.readAsString());
      
      if (data['id'] == null || data['rating'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Отсутствуют обязательные поля'}),
          headers: _getCorsHeaders(),
        );
      }

      await _statisticsService.updateRating(data['id'], data['rating'].toDouble());
      return Response.ok(
        jsonEncode({'message': 'Рейтинг обновлен'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка обновления рейтинга: $e'}),
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