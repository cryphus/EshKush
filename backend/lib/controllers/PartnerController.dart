import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../services/PartnerService.dart';
import '../model/entities/Partner.dart';

class PartnerController {
  final PartnerService _partnerService;

  PartnerController(this._partnerService);

  Future<Response> getPartner(Request request, String id) async {
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

  Future<Response> getAllPartners(Request request) async {
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

  Future<Response> createPartner(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      
      final partner = Partner(
        id: 0, // ID будет назначен базой данных
        name: data['name'],
        contactPerson: data['contact_person'],
        concactEmail: data['contact_email'],
        contactPhone: data['contact_phone'],
        contactDocument: data['contact_document'],
        maxDiscount: (data['max_discount'] ?? 0.0).toDouble(),
        createdAt: DateTime.now(),
      );

      final createdPartner = await _partnerService.createPartner(partner);
      return Response.ok(
        jsonEncode(createdPartner.toJson()),
        headers: _getCorsHeaders(),
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': 'Ошибка создания партнера: $e'}),
        headers: _getCorsHeaders(),
      );
    }
  }

  Future<Response> updatePartner(Request request, String id) async {
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

  Future<Response> deletePartner(Request request, String id) async {
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