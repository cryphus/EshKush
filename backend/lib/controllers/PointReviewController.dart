import 'package:shelf/shelf.dart';
import '../services/PointReviewService.dart';
import '../model/entities/PointReview.dart';

class PointReviewController {
  final PointReviewService _service;

  PointReviewController(this._service);

  Future<Response> getById(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id']!);
      final review = await _service.getById(id);
      if (review == null) {
        return Response.notFound('Отзыв не найден');
      }
      return Response.ok(review.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка получения отзыва: $e');
    }
  }

  Future<Response> getByPointId(Request request) async {
    try {
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      final reviews = await _service.getByPointId(pointId);
      return Response.ok(reviews.map((r) => r.toJson()).toList().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка получения отзывов: $e');
    }
  }

  Future<Response> getByUserId(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final reviews = await _service.getByUserId(userId);
      return Response.ok(reviews.map((r) => r.toJson()).toList().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка получения отзывов: $e');
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await request.readAsString();
      final json = Map<String, dynamic>.from(body as Map);
      final review = PointReview.fromJson(json);
      final created = await _service.create(review);
      return Response.ok(created.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка создания отзыва: $e');
    }
  }

  Future<Response> update(Request request) async {
    try {
      final body = await request.readAsString();
      final json = Map<String, dynamic>.from(body as Map);
      final review = PointReview.fromJson(json);
      final updated = await _service.update(review);
      return Response.ok(updated.toJson().toString());
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка обновления отзыва: $e');
    }
  }

  Future<Response> delete(Request request) async {
    try {
      final id = int.parse(request.url.queryParameters['id']!);
      await _service.delete(id);
      return Response.ok('Отзыв успешно удален');
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка удаления отзыва: $e');
    }
  }
} 