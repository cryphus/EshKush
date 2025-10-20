import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerService.dart';
import '../model/entities/Partner.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';

class PartnerController {
  final PartnerService _partnerService;
  final Router _router = Router();

  PartnerController(this._partnerService) {
    _router.get('/', _getAllPartners);
    _router.post('/', _createPartner);
    _router.get('/<id>', _getPartner);
    _router.put('/<id>', _updatePartner);
    _router.delete('/<id>', _deletePartner);
  }

  Router get router => _router;

  Future<Response> _getPartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.parse(id);
      final partner = await _partnerService.getPartner(partnerId);
      
      if (partner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Партнер не найден'}),
          headers: _getCorsHeaders(),
        );
      }

      final body = jsonEncode(partner.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения партнера', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getAllPartners(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partners = await _partnerService.getAllPartners();
      final body = jsonEncode(partners.map((p) => p.toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createPartner(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      SafeLoggingUtils.logData('Полученные данные', data);
      final sanitized = ValidationUtils.validateAndSanitizePartnerData(data);

      final partner = Partner(
        id: 0,
        userId: int.parse(sanitized['user_id'].toString()),
        name: sanitized['name'],
        contactPerson: sanitized['contact_person'],
        contactEmail: sanitized['contact_email'],
        contactPhone: sanitized['contact_phone'],
        contactDocument: sanitized['contact_document'],
        maxDiscount: (sanitized['max_discount'] ?? 0.0) as double,
        createdAt: DateTime.now(),
      );

      final createdPartner = await _partnerService.createPartner(partner);
      final out = jsonEncode(createdPartner.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания партнера', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': 'Ошибка создания партнера: $e'}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updatePartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.parse(id);
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      final sanitized = ValidationUtils.validateAndSanitizePartnerData(data);
      
      final updatedPartner = await _partnerService.updatePartner(partnerId, sanitized);
      final out = jsonEncode(updatedPartner.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка обновления партнера: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deletePartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.parse(id);
      await _partnerService.deletePartner(partnerId);
      final body = jsonEncode({'message': 'Партнер успешно удален'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка удаления партнера: $e'}),
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