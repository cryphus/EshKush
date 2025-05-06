import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PromoCodesService.dart';
import '../model/enums/DiscountType.dart';
import '../utils/AuthUtils.dart';

class PromoCodesController {
  final PromoCodesService _promoCodesService;

  PromoCodesController(this._promoCodesService);

  Future<Response> getPromoCode(Request request) async {
    try {
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

      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Неверный ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.getPromoCodeById(id);
      return Response.ok(
        jsonEncode(promoCode.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> getActivePromoCodes(Request request) async {
    try {
      final promoCodes = await _promoCodesService.getActivePromoCodes();
      return Response.ok(
        jsonEncode(promoCodes.map((p) => p.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> createPromoCode(Request request) async {
    try {
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

      final data = jsonDecode(await request.readAsString());
      
      if (!_validatePromoCodeData(data)) {
        return Response(400, 
          body: jsonEncode({'error': 'Некорректные данные'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.createPromoCode(
        code: data['code'],
        description: data['description'],
        startDate: DateTime.parse(data['startDate']),
        endDate: DateTime.parse(data['endDate']),
        minOrderSum: (data['minOrderSum'] as num).toDouble(),
        discountType: DiscountType.values.firstWhere(
          (e) => e.toString() == 'DiscountType.${data['discountType']}',
          orElse: () => DiscountType.percentage,
        ),
        discountValue: (data['discountValue'] as num).toDouble(),
        isActive: data['isActive'] ?? true,
        usageLimit: data['usageLimit'],
        applicableProducts: data['applicableProducts'] != null 
            ? List<int>.from(data['applicableProducts'])
            : null,
        applicablePoints: data['applicablePoints'] != null
            ? List<int>.from(data['applicablePoints'])
            : null,
      );

      return Response.ok(
        jsonEncode(promoCode.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updatePromoCode(Request request) async {
    try {
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

      final data = jsonDecode(await request.readAsString());
      
      if (data['id'] == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Не указан ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      final promoCode = await _promoCodesService.getPromoCodeById(data['id']);
      
      final updatedPromoCode = await _promoCodesService.createPromoCode(
        code: promoCode.code,
        description: data['description'] ?? promoCode.description,
        startDate: promoCode.startDate,
        endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : promoCode.endDate,
        minOrderSum: data['minOrderSum'] != null ? (data['minOrderSum'] as num).toDouble() : promoCode.minOrderSum,
        discountType: data['discountType'] != null 
            ? DiscountType.values.firstWhere(
                (e) => e.toString() == 'DiscountType.${data['discountType']}',
                orElse: () => DiscountType.percentage,
              )
            : promoCode.discountType,
        discountValue: data['discountValue'] != null ? (data['discountValue'] as num).toDouble() : promoCode.discountValue,
        isActive: data['isActive'] ?? promoCode.isActive,
        usageLimit: data['usageLimit'] ?? promoCode.usageLimit,
        applicableProducts: data['applicableProducts'] != null 
            ? List<int>.from(data['applicableProducts'])
            : promoCode.applicableProducts,
        applicablePoints: data['applicablePoints'] != null
            ? List<int>.from(data['applicablePoints'])
            : promoCode.applicablePoints,
      );

      await _promoCodesService.deletePromoCode(promoCode.id);

      return Response.ok(
        jsonEncode(updatedPromoCode.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> deletePromoCode(Request request) async {
    try {
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

      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Неверный ID промокода'}),
          headers: _getCorsHeaders(),
        );
      }

      await _promoCodesService.deletePromoCode(id);
      return Response.ok(
        jsonEncode({'message': 'Промокод удален'}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> calculateDiscount(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      
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

      return Response.ok(
        jsonEncode({'discount': discount}),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400, 
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  bool _isAdmin(Map<String, dynamic> payload) {
    return payload['role'] == 'admin';
  }

  bool _validatePromoCodeData(Map<String, dynamic> data) {
    if (data['code'] == null || (data['code'] as String).isEmpty) {
      return false;
    }
    if (data['description'] == null || (data['description'] as String).isEmpty) {
      return false;
    }
    if (data['startDate'] == null || data['endDate'] == null) {
      return false;
    }
    if (data['minOrderSum'] == null || (data['minOrderSum'] as num) < 0) {
      return false;
    }
    if (data['discountType'] == null || data['discountValue'] == null) {
      return false;
    }
    if ((data['discountValue'] as num) <= 0) {
      return false;
    }
    return true;
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