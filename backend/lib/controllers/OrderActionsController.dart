import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/OrderActionsService.dart';
import '../model/enums/ActionType.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class OrderActionsController {
  final OrderActionsService _orderActionsService;
  final Router _router = Router();

  OrderActionsController(this._orderActionsService);

  Router get router => _router
    ..get('/one', getAction)
    ..get('/by-order', getOrderActions)
    ..get('/by-partner', getPartnerActions)
    ..post('/', createAction)
    ..post('/update-type', updateActionType)
    ..post('/update-description', updateActionDescription)
    ..post('/deactivate', deactivateAction)
    ..post('/activate', activateAction)
    ..get('/active', getActiveActions);

  Future<Response> getAction(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID РґРµР№СЃС‚РІРёСЏ');
      }

      final action = await _orderActionsService.getActionById(id);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getOrderActions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final orderId = int.tryParse(request.url.queryParameters['orderId'] ?? '');
      if (orderId == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID Р·Р°РєР°Р·Р°');
      }

      final actions = await _orderActionsService.getOrderActions(orderId);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРµР№СЃС‚РІРёР№ Р·Р°РєР°Р·Р°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getPartnerActions(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final partnerId = int.tryParse(request.url.queryParameters['partnerId'] ?? '');
      if (partnerId == null) {
        return _createErrorResponse(400, 'РќРµРІРµСЂРЅС‹Р№ ID РїР°СЂС‚РЅРµСЂР°');
      }

      final actions = await _orderActionsService.getPartnerActions(partnerId);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРµР№СЃС‚РІРёР№ РїР°СЂС‚РЅРµСЂР°', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> createAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
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

        await LoggingUtils.logInfo('create order action', context: {'actionId': action.id, ...sanitizedData}, requestId: RequestContextUtils.getRequestId(request));

        final headers = _getCorsHeaders();
        final responseBody = jsonEncode(action.toJson());
        await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
        return Response.ok(responseBody, headers: headers);
      } on ValidationException catch (e) {
        return _createErrorResponse(400, e.toString());
      }
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> updateActionType(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final data = jsonDecode(body);
      if (data['id'] == null || data['actionType'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅС‹ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїР°СЂР°РјРµС‚СЂС‹');
      }

      final action = await _orderActionsService.updateActionType(
        data['id'],
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.${data['actionType']}',
          orElse: () => ActionType.create,
        ),
      );

      await LoggingUtils.logInfo('update order action type', context: {'actionId': action.id, ...data}, requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С‚РёРїР° РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> updateActionDescription(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      AuthUtils.verifyToken(token);
      final data = jsonDecode(body);
      
      if (data['id'] == null || data['description'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅС‹ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹Рµ РїР°СЂР°РјРµС‚СЂС‹');
      }

      if (!ValidationUtils.isValidDescription(data['description'])) {
        return _createErrorResponse(400, 'РќРµРєРѕСЂСЂРµРєС‚РЅРѕРµ РѕРїРёСЃР°РЅРёРµ');
      }

      final action = await _orderActionsService.updateActionDescription(
        data['id'],
        data['description'],
      );

      await LoggingUtils.logInfo('update order action description', context: {'actionId': action.id, ...data}, requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РѕРїРёСЃР°РЅРёСЏ РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> deactivateAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final data = jsonDecode(body);
      if (data['id'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅ ID РґРµР№СЃС‚РІРёСЏ');
      }

      final action = await _orderActionsService.deactivateAction(data['id']);

      await LoggingUtils.logInfo('deactivate order action', context: {'actionId': action.id, ...data}, requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РґРµР°РєС‚РёРІР°С†РёРё РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> activateAction(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final data = jsonDecode(body);
      if (data['id'] == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅ ID РґРµР№СЃС‚РІРёСЏ');
      }

      final action = await _orderActionsService.activateAction(data['id']);

      await LoggingUtils.logInfo('activate order action', context: {'actionId': action.id, ...data}, requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° Р°РєС‚РёРІР°С†РёРё РґРµР№СЃС‚РІРёСЏ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getActionsByType(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final type = request.url.queryParameters['type'];
      if (type == null) {
        return _createErrorResponse(400, 'РќРµ СѓРєР°Р·Р°РЅ С‚РёРї РґРµР№СЃС‚РІРёСЏ');
      }

      final actions = await _orderActionsService.getActionsByType(
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.$type',
          orElse: () => ActionType.create,
        ),
      );

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРµР№СЃС‚РІРёР№ РїРѕ С‚РёРїСѓ', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
    }
  }

  Future<Response> getActiveActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
        request.method,
        request.url.path,
        request.headers,
        null,
        requestId: RequestContextUtils.getRequestId(request),
      );

      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return _createErrorResponse(401, 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ');
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return _createErrorResponse(403, 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°');
      }

      final actions = await _orderActionsService.getActiveActions();
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody, requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р°РєС‚РёРІРЅС‹С… РґРµР№СЃС‚РІРёР№', e, requestId: RequestContextUtils.getRequestId(request));
      return _createErrorResponse(400, 'РћС€РёР±РєР°: $e');
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
    return {'Content-Type': 'application/json'};
  }
} 
