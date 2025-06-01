import 'package:shelf/shelf.dart';
import '../services/UserFavoriteService.dart';
import '../model/entities/UserFavorite.dart';
import 'dart:convert';

class UserFavoriteController {
  final UserFavoriteService _service;

  UserFavoriteController(this._service);

  Future<Response> getByUserId(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final favorites = await _service.getByUserId(userId);
      return Response.ok(
        favorites.map((f) => f.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> getByPointId(Request request) async {
    try {
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      final favorites = await _service.getByPointId(pointId);
      return Response.ok(
        favorites.map((f) => f.toJson()).toList().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> addToFavorites(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final favorite = UserFavorite.fromJson(json);
      final result = await _service.addToFavorites(favorite);
      return Response.ok(
        result.toJson().toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> removeFromFavorites(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      await _service.removeFromFavorites(userId, pointId);
      return Response.ok(
        {'message': 'Место успешно удалено из избранного'}.toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> isFavorite(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['userId']!);
      final pointId = int.parse(request.url.queryParameters['pointId']!);
      final result = await _service.isFavorite(userId, pointId);
      return Response.ok(
        {'isFavorite': result}.toString(),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: {'error': e.toString()}.toString(),
        headers: {'content-type': 'application/json'},
      );
    }
  }
} 