import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PromoCodesService.dart';
import '../model/enums/DiscountType.dart';
import '../utils/AuthUtils.dart';
import '../utils/ValidationUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../model/dto/responses/PromoCodeResponseDto.dart';
import '../model/dto/requests/CreatePromoCodeDto.dart';

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
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРІРµСЂРЅС‹Р№ ID РїСЂРѕРјРѕРєРѕРґР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.getPromoCodeById(id);
      final promoCodeDto = PromoCodeResponseDto.fromEntity(promoCode);
      final body = jsonEncode(promoCodeDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕРјРѕРєРѕРґР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getActivePromoCodes(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final promoCodes = await _promoCodesService.getActivePromoCodes();
      final body = jsonEncode(promoCodes.map((p) => PromoCodeResponseDto.fromEntity(p).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р°РєС‚РёРІРЅС‹С… РїСЂРѕРјРѕРєРѕРґРѕРІ', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _createPromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      final createDto = CreatePromoCodeDto.fromJson(data);

      final promoCode = await _promoCodesService.createPromoCode(
        code: createDto.code,
        description: createDto.description,
        startDate: createDto.startDate,
        endDate: createDto.endDate,
        minOrderSum: createDto.minOrderSum,
        discountType: DiscountType.values.firstWhere(
          (e) => e.name.toLowerCase() == createDto.discountType.toLowerCase(),
          orElse: () => DiscountType.percentage,
        ),
        discountValue: createDto.discountValue,
        isActive: true,
        usageLimit: createDto.usageLimit,
        applicableProducts: createDto.applicableProducts,
        applicablePoints: createDto.applicablePoints,
      );

      final promoCodeDto = PromoCodeResponseDto.fromEntity(promoCode);
      final body = jsonEncode(promoCodeDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїСЂРѕРјРѕРєРѕРґР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updatePromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      final sanitized = ValidationUtils.validateAndSanitizePromoCodeData(data);
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµ СѓРєР°Р·Р°РЅ ID РїСЂРѕРјРѕРєРѕРґР°'}),
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
      await LoggingUtils.logError('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕРјРѕРєРѕРґР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deletePromoCode(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final token = request.headers['authorization']?.replaceAll('Bearer ', '');
      if (token == null) {
        return Response(401, 
          body: jsonEncode({'error': 'РўСЂРµР±СѓРµС‚СЃСЏ Р°РІС‚РѕСЂРёР·Р°С†РёСЏ'}),
          headers: _getCorsHeaders(),
        );
      }

      final payload = AuthUtils.verifyToken(token);
      if (!_isAdmin(payload)) {
        return Response(403, 
          body: jsonEncode({'error': 'РќРµС‚ РїСЂР°РІ РґРѕСЃС‚СѓРїР°'}),
          headers: _getCorsHeaders(),
        );
      }

      final id = int.tryParse(request.params['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµРІРµСЂРЅС‹Р№ ID РїСЂРѕРјРѕРєРѕРґР°'}),
          headers: _getCorsHeaders(),
        );
      }

      await _promoCodesService.deletePromoCode(id);
      final body = jsonEncode({'message': 'РџСЂРѕРјРѕРєРѕРґ СѓРґР°Р»РµРЅ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕРјРѕРєРѕРґР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _calculateDiscount(Request request) async {
    try {
      final raw = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, raw, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(raw);
      
      if (data['code'] == null || data['orderSum'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'РќРµ СѓРєР°Р·Р°РЅ РєРѕРґ РёР»Рё СЃСѓРјРјР° Р·Р°РєР°Р·Р°'}),
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
      await LoggingUtils.logError('РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р° СЃРєРёРґРєРё', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'РћС€РёР±РєР°: $e'}), headers: _getCorsHeaders());
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
