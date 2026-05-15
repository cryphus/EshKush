import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/OrderActionsService.dart';
import '../model/enums/ActionType.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ErrorResponseUtils.dart';
import '../utils/RequestBodyUtils.dart';

class OrderActionsController {
  final OrderActionsService _orderActionsService;
  final Router _router = Router();

  OrderActionsController(this._orderActionsService);

  Router get router => _router
    ..get('/', getActiveActions)
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
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Неверный ID действия',
            headers: _getCorsHeaders());
      }

      final action = await _orderActionsService.getActionById(id);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getOrderActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final orderId =
          int.tryParse(request.url.queryParameters['orderId'] ?? '');
      if (orderId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Неверный ID заказа',
            headers: _getCorsHeaders());
      }

      final actions = await _orderActionsService.getOrderActions(orderId);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий заказа', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getPartnerActions(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final partnerId =
          int.tryParse(request.url.queryParameters['partnerId'] ?? '');
      if (partnerId == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Неверный ID партнёра',
            headers: _getCorsHeaders());
      }

      final actions = await _orderActionsService.getPartnerActions(partnerId);
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий партнера', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> createAction(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = RequestBodyUtils.decodeJsonObject(body);

      try {
        final sanitizedData =
            ValidationUtils.validateAndSanitizeActionData(data);
        final action = await _orderActionsService.createAction(
          orderId: sanitizedData['orderId'],
          partnerId: sanitizedData['partnerId'],
          actionDescription: sanitizedData['actionDescription'],
          actionType: sanitizedData['actionType'] != null
              ? ActionType.values.firstWhere(
                  (e) =>
                      e.toString() ==
                      'ActionType.${sanitizedData['actionType']}',
                  orElse: () => ActionType.create,
                )
              : ActionType.create,
        );

        await LoggingUtils.logInfo('create order action',
            context: {'actionId': action.id, ...sanitizedData},
            requestId: RequestContextUtils.getRequestId(request));

        final headers = _getCorsHeaders();
        final responseBody = jsonEncode(action.toJson());
        await LoggingUtils.logResponse(200, headers, responseBody,
            requestId: RequestContextUtils.getRequestId(request));
        return Response.ok(responseBody, headers: headers);
      } on ValidationException catch (e) {
        return ErrorResponseUtils.errorResponse(e,
            requestId: RequestContextUtils.getRequestId(request),
            headers: _getCorsHeaders());
      }
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> updateActionType(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final data = RequestBodyUtils.decodeJsonObject(body);
      if (data['id'] == null || data['actionType'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указаны обязательные параметры',
            headers: _getCorsHeaders());
      }

      final action = await _orderActionsService.updateActionType(
        data['id'],
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.${data['actionType']}',
          orElse: () => ActionType.create,
        ),
      );

      await LoggingUtils.logInfo('update order action type',
          context: {'actionId': action.id, ...data},
          requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления типа действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> updateActionDescription(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      final data = RequestBodyUtils.decodeJsonObject(body);

      if (data['id'] == null || data['description'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указаны обязательные параметры',
            headers: _getCorsHeaders());
      }

      if (!ValidationUtils.isValidDescription(data['description'])) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Некорректное описание',
            headers: _getCorsHeaders());
      }

      final action = await _orderActionsService.updateActionDescription(
        data['id'],
        data['description'],
      );

      await LoggingUtils.logInfo('update order action description',
          context: {'actionId': action.id, ...data},
          requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления описания действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> deactivateAction(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final data = RequestBodyUtils.decodeJsonObject(body);
      if (data['id'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указан ID действия',
            headers: _getCorsHeaders());
      }

      final action = await _orderActionsService.deactivateAction(data['id']);

      await LoggingUtils.logInfo('deactivate order action',
          context: {'actionId': action.id, ...data},
          requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка деактивации действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> activateAction(Request request) async {
    try {
      final body = await RequestBodyUtils.readRequiredBody(request);
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, body,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final data = RequestBodyUtils.decodeJsonObject(body);
      if (data['id'] == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указан ID действия',
            headers: _getCorsHeaders());
      }

      final action = await _orderActionsService.activateAction(data['id']);

      await LoggingUtils.logInfo('activate order action',
          context: {'actionId': action.id, ...data},
          requestId: RequestContextUtils.getRequestId(request));

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(action.toJson());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка активации действия', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Future<Response> getActionsByType(Request request) async {
    try {
      await LoggingUtils.logRequest(
          request.method, request.url.path, request.headers, null,
          requestId: RequestContextUtils.getRequestId(request));

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final type = request.url.queryParameters['type'];
      if (type == null) {
        return ErrorResponseUtils.errorResponseWithMessage(
            'Не указан тип действия',
            headers: _getCorsHeaders());
      }

      final actions = await _orderActionsService.getActionsByType(
        ActionType.values.firstWhere(
          (e) => e.toString() == 'ActionType.$type',
          orElse: () => ActionType.create,
        ),
      );

      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения действий по типу', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
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

      final unauthorized = RequestContextUtils.requireUserOr401(request,
          headers: _getCorsHeaders());
      if (unauthorized != null) return unauthorized;
      if (!RequestContextUtils.isAdmin(request)) {
        return ErrorResponseUtils.errorResponseWithMessage('Нет прав доступа',
            code: ErrorCode.forbidden, headers: _getCorsHeaders());
      }

      final actions = await _orderActionsService.getActiveActions();
      final headers = _getCorsHeaders();
      final responseBody = jsonEncode(actions.map((a) => a.toJson()).toList());
      await LoggingUtils.logResponse(200, headers, responseBody,
          requestId: RequestContextUtils.getRequestId(request));
      return Response.ok(responseBody, headers: headers);
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения активных действий', e,
          requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e,
          requestId: RequestContextUtils.getRequestId(request),
          headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
