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
      final partnerId = int.tryParse(id);
      if (partnerId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
      final partner = await _partnerService.getPartner(partnerId);
      
      if (partner == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Партнёр не найден', code: ErrorCode.notFound, headers: _getCorsHeaders());
      }

      // Для админов используйте отдельный endpoint с PartnerAdminDto
      final partnerDto = PartnerResponseDto.fromEntity(partner);
      final body = jsonEncode(partnerDto.toJson());
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения партнёра', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
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
        contactPerson: sanitized['contact_person'] != null
            ? int.tryParse(sanitized['contact_person'].toString())
            : int.tryParse(sanitized['user_id'].toString()),
        contactEmail: sanitized['contact_email']?.toString(),
        contactPhone: sanitized['contact_phone']?.toString(),
        contactDocument: sanitized['contact_document']?.toString() ?? '',
        maxDiscount: (sanitized['max_discount'] ?? 0.0) is num ? (sanitized['max_discount'] ?? 0.0).toDouble() : 0.0,
        createdAt: DateTime.now(),
      );

      final createdPartner = await _partnerService.createPartner(partner);
      final partnerDto = PartnerResponseDto.fromEntity(createdPartner);
      final out = jsonEncode(partnerDto.toJson());
      final resp = Response.ok(out, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, out, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      await LoggingUtils.logError('Ошибка создания партнёра', e, requestId: RequestContextUtils.getRequestId(request));
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _updatePartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.tryParse(id);
      if (partnerId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
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
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Future<Response> _deletePartner(Request request, String id) async {
    try {
      await LoggingUtils.logRequest(request.method, request.url.path, request.headers, null, requestId: RequestContextUtils.getRequestId(request));
      final partnerId = int.tryParse(id);
      if (partnerId == null) {
        return ErrorResponseUtils.errorResponseWithMessage('Некорректный ID', code: ErrorCode.badRequest, headers: _getCorsHeaders());
      }
      await _partnerService.deletePartner(partnerId);
      final body = jsonEncode({'message': 'Партнёр успешно удалён'});
      final resp = Response.ok(body, headers: _getCorsHeaders());
      await LoggingUtils.logResponse(resp.statusCode, resp.headers, body, requestId: RequestContextUtils.getRequestId(request));
      return resp;
    } catch (e) {
      return ErrorResponseUtils.errorResponse(e, requestId: RequestContextUtils.getRequestId(request), headers: _getCorsHeaders());
    }
  }

  Map<String, String> _getCorsHeaders() {
    return {'Content-Type': 'application/json'};
  }
} 
