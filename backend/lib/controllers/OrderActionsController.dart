import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/OrderActionsService.dart';
import '../model/enums/ActionType.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';

class OrderActionsController {
  final OrderActionsService _orderActionsService;

  OrderActionsController(this._orderActionsService);

  Future<Response> getAction(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return _createErrorResponse(400, 'Неверный ID действия');
      }

      final action = await _orderActionsService.getActionById(id);
      
      final response = Response.ok(
        jsonEncode(action.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getOrderActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final orderId = int.tryParse(request.url.queryParameters['orderId'] ?? '');
      if (orderId == null) {
        return _createErrorResponse(400, 'Неверный ID заказа');
      }

      final actions = await _orderActionsService.getOrderActions(orderId);
      
      final response = Response.ok(
        jsonEncode(actions.map((a) => a.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий заказа', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getPartnerActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final partnerId = int.tryParse(request.url.queryParameters['partnerId'] ?? '');
      if (partnerId == null) {
        return _createErrorResponse(400, 'Неверный ID партнера');
      }

      final actions = await _orderActionsService.getPartnerActions(partnerId);
      
      final response = Response.ok(
        jsonEncode(actions.map((a) => a.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий партнера', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> createAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      try {
        final sanitizedData = ValidationUtils.validateAndSanitizeActionData(data);
        final action = await _orderActionsService.createAction(
          orderId: sanitizedData['orderId'],
          partnerId: sanitizedData['partnerId'],
          actionDescription: sanitizedData['actionDescription'],
          actionType: sanitizedData['actionType'] != null 
              ? ActionType.values.firstWhere(
                  (e) => e.toString() == 'ActionType.${sanitizedData['actionType']}',
                  orElse: () => ActionType.create,
                )
              : ActionType.create,
        );

        await LoggingUtils.logActionOperation('create', action.id, sanitizedData);
        
        final response = Response.ok(
          jsonEncode(action.toJson()),
          headers: _getCorsHeaders(),
        );

        await LoggingUtils.logResponse(
          response.statusCode,
          response.headers,
          await response.readAsString(),
        );

        return response;
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> updateActionType(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final data = jsonDecode(body);
      if (data['id'] == null || data['actionType'] == null) {
        return _createErrorResponse(400, 'Не указаны обязательные параметры');
      }

      final action = await _orderActionsService.updateActionType(
        data['id'],
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.${data['actionType']}',
          orElse: () => ActionType.create,
        ),
      );

      await LoggingUtils.logActionOperation('update_type', action.id, data);
      
      final response = Response.ok(
        jsonEncode(action.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления типа действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> updateActionDescription(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['description'] == null) {
        return _createErrorResponse(400, 'Не указаны обязательные параметры');
      }

      if (!ValidationUtils.isValidDescription(data['description'])) {
        return _createErrorResponse(400, 'Некорректное описание');
      }

      final action = await _orderActionsService.updateActionDescription(
        data['id'],
        data['description'],
      );

      await LoggingUtils.logActionOperation('update_description', action.id, data);
      
      final response = Response.ok(
        jsonEncode(action.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления описания действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> deactivateAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final data = jsonDecode(body);
      if (data['id'] == null) {
        return _createErrorResponse(400, 'Не указан ID действия');
      }

      final action = await _orderActionsService.deactivateAction(data['id']);

      await LoggingUtils.logActionOperation('deactivate', action.id, data);
      
      final response = Response.ok(
        jsonEncode(action.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка деактивации действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> activateAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        body,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final data = jsonDecode(body);
      if (data['id'] == null) {
        return _createErrorResponse(400, 'Не указан ID действия');
      }

      final action = await _orderActionsService.activateAction(data['id']);

      await LoggingUtils.logActionOperation('activate', action.id, data);
      
      final response = Response.ok(
        jsonEncode(action.toJson()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка активации действия', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getActionsByType(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final type = request.url.queryParameters['type'];
      if (type == null) {
        return _createErrorResponse(400, 'Не указан тип действия');
      }

      final actions = await _orderActionsService.getActionsByType(
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.$type',
          orElse: () => ActionType.create,
        ),
      );
      
      final response = Response.ok(
        jsonEncode(actions.map((a) => a.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий по типу', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  Future<Response> getActiveActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'Требуется авторизация');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'Нет прав доступа');
      }

      final actions = await _orderActionsService.getActiveActions();
      
      final response = Response.ok(
        jsonEncode(actions.map((a) => a.toJson()).toList()),
        headers: _getCorsHeaders(),
      );

      await LoggingUtils.logResponse(
        response.statusCode,
        response.headers,
        await response.readAsString(),
      );

      return response;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения активных действий', e);
      return _createErrorResponse(400, 'Ошибка: $e');
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
  }

  Response _createErrorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: _getCorsHeaders(),
    );
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