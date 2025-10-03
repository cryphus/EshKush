import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import '../services/PartnerService.dart';
import '../model/entities/Partner.dart';
import '../utils/SafeLoggingUtils.dart';

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
      final partnerId = int.parse(id);
      final partner = await _partnerService.getPartner(partnerId);
      
      if (partner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Партнер не найден'}),
          headers: _getCorsHeaders(),
        );
      }

      return Response.ok(
        jsonEncode(partner.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _getAllPartners(Request request) async {
    try {
      final partners = await _partnerService.getAllPartners();
      return Response.ok(
        jsonEncode(partners.map((p) => p.toJson()).toList()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _createPartner(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      SafeLoggingUtils.logData('Полученные данные', data);
      
      final now = DateTime.now().toIso8601String();
      print('Создаем партнера с данными:');
      print('user_id: ${data['user_id']}');
      print('name: ${data['name']}');
      print('contact_person: ${data['contact_person']}');
      print('contact_email: ${data['contact_email']}');
      print('contact_phone: ${data['contact_phone']}');
      print('contact_document: ${data['contact_document']}');
      print('max_discount: ${data['max_discount']}');
      print('created_at: $now');
      
      final partner = Partner(
        id: 0,
        userId: data['user_id'],
        name: data['name'],
        contactPerson: data['contact_person'],
        contactEmail: data['contact_email'],
        contactPhone: data['contact_phone'],
        contactDocument: data['contact_document'],
        maxDiscount: data['max_discount'] is String 
            ? double.parse(data['max_discount']) 
            : (data['max_discount'] ?? 0.0).toDouble(),
        createdAt: DateTime.parse(now),
      );

      final createdPartner = await _partnerService.createPartner(partner);
      return Response.ok(
        jsonEncode(createdPartner.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      print('Ошибка при создании партнера: $e');
      return Response(400,
        body: jsonEncode({'error': 'Ошибка создания партнера: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _updatePartner(Request request, String id) async {
    try {
      final partnerId = int.parse(id);
      final data = jsonDecode(await request.readAsString());
      
      final updatedPartner = await _partnerService.updatePartner(partnerId, data);
      return Response.ok(
        jsonEncode(updatedPartner.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка обновления партнера: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> _deletePartner(Request request, String id) async {
    try {
      final partnerId = int.parse(id);
      await _partnerService.deletePartner(partnerId);
      return Response.ok(
        jsonEncode({'message': 'Партнер успешно удален'}),
        headers: _getCorsHeaders(),
      );
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