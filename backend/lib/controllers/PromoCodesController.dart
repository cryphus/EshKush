import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PromoCodesService.dart';
import '../model/enums/DiscountType.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';

class PromoCodesController {
  final PromoCodesService _promoCodesService;
  final Router _router = Router();

  PromoCodesController(this._promoCodesService) {
    _router.get('/active', _getActivePromoCodes);
    _router.get('/<id>', _getPromoCode);
    _router.post('/', _createPromoCode);
    _router.put('/', _updatePromoCode);
    _router.delete('/<id>', _deletePromoCode);
    _router.post('/calculate', _calculateDiscount);
  }

  Router get router => _router;

  Future<Response> _getPromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'Нет прав доступа'}),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Неверный ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.getPromoCodeById(id);
      final body = jsonEncode(promoCode.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения промокода', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getActivePromoCodes(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final promoCodes = await _promoCodesService.getActivePromoCodes();
      final body = jsonEncode(promoCodes.map((p) => p.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения активных промокодов', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _createPromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'Нет прав доступа'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final sanitized = ValidationUtils.validateAndSanitizePromoCodeData(data);

      final promoCode = await _promoCodesService.createPromoCode(
        code: sanitized['code'] as String,
        description: sanitized['description'] as String,
        startDate: DateTime.parse(sanitized['startDate'] as String),
        endDate: DateTime.parse(sanitized['endDate'] as String),
        minOrderSum: sanitized['minOrderSum'] as double,
        discountType: DiscountType.values.firstWhere(
          (e) => e.toString() == 'DiscountType.${sanitized['discountType']}',
          orElse: () => DiscountType.percentage,
        ),
        discountValue: sanitized['discountValue'] as double,
        isActive: sanitized['isActive'] as bool? ?? true,
        usageLimit: sanitized['usageLimit'] as int?,
        applicableProducts: sanitized['applicableProducts'] != null 
            ? List<int>.from(sanitized['applicableProducts'])
            : null,
        applicablePoints: sanitized['applicablePoints'] != null
            ? List<int>.from(sanitized['applicablePoints'])
            : null,
      );

      final body = jsonEncode(promoCode.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания промокода', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updatePromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'Нет прав доступа'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final sanitized = ValidationUtils.validateAndSanitizePromoCodeData(data);
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Не указан ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.getPromoCodeById(sanitized['id']);
      
      promoCode.description = sanitized['description'] ?? promoCode.description;
      promoCode.endDate = sanitized['endDate'] != null ? DateTime.parse(sanitized['endDate']) : promoCode.endDate;
      promoCode.minOrderSum = sanitized['minOrderSum'] != null ? (sanitized['minOrderSum'] as num).toDouble() : promoCode.minOrderSum;
      promoCode.discountType = sanitized['discountType'] != null 
          ? DiscountType.values.firstWhere(
              (e) => e.toString() == 'DiscountType.${sanitized['discountType']}',
              orElse: () => DiscountType.percentage,
            )
          : promoCode.discountType;
      promoCode.discountValue = sanitized['discountValue'] != null ? (sanitized['discountValue'] as num).toDouble() : promoCode.discountValue;
      promoCode.isActive = sanitized['isActive'] ?? promoCode.isActive;
      promoCode.usageLimit = sanitized['usageLimit'] ?? promoCode.usageLimit;
      promoCode.applicableProducts = sanitized['applicableProducts'] != null 
          ? List<int>.from(sanitized['applicableProducts'])
          : promoCode.applicableProducts;
      promoCode.applicablePoints = sanitized['applicablePoints'] != null
          ? List<int>.from(sanitized['applicablePoints'])
          : promoCode.applicablePoints;

      final updatedPromoCode = await _promoCodesService.updatePromoCode(promoCode);

      final body = jsonEncode(updatedPromoCode.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка обновления промокода', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deletePromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'Требуется авторизация'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'Нет прав доступа'}),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Неверный ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      await _promoCodesService.deletePromoCode(id);
      final body = jsonEncode({'message': 'Промокод удален'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления промокода', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _calculateDiscount(Request request) async {
    try {
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['code'] == null || data['orderSum'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Не указан код или сумма заказа'}),
          headers: _getCorsHeaders(),
        );
      }

      final discount = await _promoCodesService.calculateDiscount(
        data['code'],
        (data['orderSum'] as num).toDouble(),
        data['productId'],
        data['pointId'],
      );

      final body = jsonEncode({'discount': discount});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка расчёта скидки', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
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