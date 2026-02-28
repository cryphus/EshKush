import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerService.dart';
import '../model/entities/Partner.dart';
import '../utils/SafeLoggingUtils.dart';
import '../utils/LoggingUtils.dart';
import '../utils/RequestContextUtils.dart';
import '../utils/ValidationUtils.dart';
import '../model/dto/responses/PartnerResponseDto.dart';
import '../utils/AuthUtils.dart';
import '../utils/ErrorResponseUtils.dart';

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
          jsonEncode({'error': 'РџР°СЂС‚РЅРµСЂ РЅРµ РЅР°Р№РґРµРЅ'}),
          headers: _getCorsHeaders(),
        );
      }

      // Р”Р»СЏ Р°РґРјРёРЅРѕРІ РёСЃРїРѕР»СЊР·СѓР№С‚Рµ РѕС‚РґРµР»СЊРЅС‹Р№ endpoint СЃ PartnerAdminDto
      final partnerDto = PartnerResponseDto.fromEntity(partner);
      final body = jsonEncode(partnerDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїР°СЂС‚РЅРµСЂР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
    }
  }

  Future<Response> _getAllPartners(Request request) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partners = await _partnerService.getAllPartners();
      final body = jsonEncode(partners.map((p) => PartnerResponseDto.fromEntity(p).toJson()).toList());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createPartner(Request request) async {
    try {
      final body = await request.readAsString();
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, body, requestId: RequestContextUtils.getRequestId(request));
      final data = jsonDecode(body);
      SafeLoggingUtils.logData('РџРѕР»СѓС‡РµРЅРЅС‹Рµ РґР°РЅРЅС‹Рµ', data);
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
      final partnerDto = PartnerResponseDto.fromEntity(createdPartner);
      final out = jsonEncode(partnerDto.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїР°СЂС‚РЅРµСЂР°', e, requestId: RequestContextUtils.getRequestId(request));
      return Response(400, body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}), headers: _getCorsHeaders());
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
      final partnerDto = PartnerResponseDto.fromEntity(updatedPartner);
      final out = jsonEncode(partnerDto.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deletePartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.parse(id);
      await _partnerService.deletePartner(partnerId);
      final body = jsonEncode({'message': 'РџР°СЂС‚РЅРµСЂ СѓСЃРїРµС€РЅРѕ СѓРґР°Р»РµРЅ'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': ErrorResponseUtils.clientSafeErrorMessage(e)}),
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
