import '../repositories/PointRepository.dart';
import '../model/entities/Point.dart';
import '../model/entities/PointCategory.dart';
import '../model/entities/PointReview.dart';

class PointService {
  final PointRepository _pointRepository;

  PointService(this._pointRepository);

  Future<Point> getPointById(int id) async {
    try {
      final result = await _pointRepository.findById(id);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
      return result;
    } catch (e) {
      print('Ошибка получения точки: $e');
      rethrow;
    }
  }

  Future<List<Point>> getAllPoints() async {
    try {
      return await _pointRepository.findAll();
    } catch (e) {
      print('Ошибка получения списка точек: $e');
      rethrow;
    }
  }

  Future<List<Point>> getPointsByCategory(int categoryId) async {
    try {
      return await _pointRepository.findByCategory(categoryId);
    } catch (e) {
      print('Ошибка получения точек по категории: $e');
      rethrow;
    }
  }

  Future<List<PointCategory>> getPointCategories(int pointId) async {
    try {
      return await _pointRepository.getCategoriesForPoint(pointId);
    } catch (e) {
      print('Ошибка получения категорий точки: $e');
      rethrow;
    }
  }

  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      _validatePointData(data);
      
      final result = await _pointRepository.createPoint(data);
      return result;
    } catch (e) {
      print('Ошибка создания точки: $e');
      rethrow;
    }
  }

  Future<Point> updatePoint(int id, Map<String, dynamic> data) async {
    try {
      _validatePointData(data);
      
      final result = await _pointRepository.updatePoint(id, data);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
      return result;
    } catch (e) {
      print('Ошибка обновления точки: $e');
      rethrow;
    }
  }

  Future<void> deletePoint(int id) async {
    try {
      final result = await _pointRepository.deletePoint(id);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
    } catch (e) {
      print('Ошибка удаления точки: $e');
      rethrow;
    }
  }

  Future<void> updateRating(int pointId, double rating) async {
    try {
      if (rating < 0 || rating > 5) {
        throw Exception('Рейтинг должен быть от 0 до 5');
      }
      
      final result = await _pointRepository.updateRating(pointId, rating);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
      rethrow;
    }
  }

  Future<void> updatePointCategories(int pointId, List<int> categoryIds) async {
    try {
      await _pointRepository.updatePointCategories(pointId, categoryIds);
    } catch (e) {
      print('Ошибка обновления категорий точки: $e');
      rethrow;
    }
  }

  Future<List<PointReview>> getPointReviews(int pointId) async {
    try {
      return await _pointRepository.getPointReviews(pointId);
    } catch (e) {
      print('Ошибка получения отзывов точки: $e');
      rethrow;
    }
  }

  Future<PointReview> createPointReview(Map<String, dynamic> data) async {
    try {
      final result = await _pointRepository.createPointReview(data);
      return result;
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      rethrow;
    }
  }

  void _validatePointData(Map<String, dynamic> data) {
    if (data['name'] != null && (data['name'] as String).isEmpty) {
      throw Exception('Название точки не может быть пустым');
    }
    if (data['address'] != null && (data['address'] as String).isEmpty) {
      throw Exception('Адрес не может быть пустым');
    }
    if (data['city_id'] != null && data['city_id'] <= 0) {
      throw Exception('Некорректный ID города');
    }
    if (data['partner_id'] != null && data['partner_id'] <= 0) {
      throw Exception('Некорректный ID партнера');
    }
    if (data['longitude'] != null && ((data['longitude'] as num) < -180 || (data['longitude'] as num) > 180)) {
      throw Exception('Некорректная долгота');
    }
    if (data['latitude'] != null && ((data['latitude'] as num) < -90 || (data['latitude'] as num) > 90)) {
      throw Exception('Некорректная широта');
    }
  }
} 