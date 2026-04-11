import '../repositories/PointRepository.dart';
import '../model/entities/Point.dart';
import '../model/entities/PointCategory.dart';
import '../model/entities/PointReview.dart';
import '../model/entities/NearbyPoint.dart';
import 'CacheService.dart';

class PointService {
  final PointRepository _pointRepository;
  final CacheService _cacheService;

  PointService(this._pointRepository, this._cacheService);

  Future<Point> getPointById(int id) async {
    try {
      // Пытаемся получить из кеша
      final cacheKey = CacheKeys.point(id);
      final cachedPoint = await _cacheService.get<Point>(cacheKey);
      if (cachedPoint != null) {
        return cachedPoint;
      }

      // Если нет в кеше, получаем из БД
      final result = await _pointRepository.findById(id);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
      
      // Сохраняем в кеш
      await _cacheService.set(cacheKey, result, ttl: CacheTTL.point);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Point>> getAllPoints({int limit = 20, int offset = 0}) async {
    try {
      if (limit == 20 && offset == 0) {
        final cacheKey = CacheKeys.allPoints();
        final cachedData = await _cacheService.get<List>(cacheKey);
        if (cachedData != null) {
          return cachedData.map((json) => Point.fromJson(json as Map<String, dynamic>)).toList();
        }
        final points = await _pointRepository.findAll(limit: limit, offset: offset);
        await _cacheService.set(cacheKey, points, ttl: CacheTTL.point);
        return points;
      }
      return await _pointRepository.findAll(limit: limit, offset: offset);
    } catch (e) {
      rethrow;
    }
  }

  /// Поиск точек рядом с координатами пользователя.
  /// [radiusM] ограничен 50 км, [limit] — 200 точек.
  Future<List<NearbyPoint>> getPointsNearby({
    required double lat,
    required double lon,
    required double radiusM,
    int limit = 100,
  }) async {
    try {
      if (lat < -90 || lat > 90) {
        throw Exception('Некорректная широта');
      }
      if (lon < -180 || lon > 180) {
        throw Exception('Некорректная долгота');
      }
      if (radiusM <= 0) {
        throw Exception('Радиус должен быть положительным');
      }
      final safeRadius = radiusM.clamp(1.0, 50000.0);
      final safeLimit = limit.clamp(1, 200);

      return await _pointRepository.findNearby(
        lat: lat,
        lon: lon,
        radiusM: safeRadius.toDouble(),
        limit: safeLimit,
      );
    } catch (e) {
      print('Ошибка геопоиска точек: $e');
      rethrow;
    }
  }

  Future<List<Point>> getPointsByCategory(int categoryId) async {
    try {
      if (limit == 20 && offset == 0) {
        final cacheKey = CacheKeys.pointsByCategory(categoryId);
        final cachedData = await _cacheService.get<List>(cacheKey);
        if (cachedData != null) {
          return cachedData.map((json) => Point.fromJson(json as Map<String, dynamic>)).toList();
        }
        final points = await _pointRepository.findByCategory(categoryId, limit: limit, offset: offset);
        await _cacheService.set(cacheKey, points, ttl: CacheTTL.point);
        return points;
      }
      return await _pointRepository.findByCategory(categoryId, limit: limit, offset: offset);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointCategory>> getPointCategories(int pointId) async {
    try {
      return await _pointRepository.getCategoriesForPoint(pointId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      _validatePointData(data);
      
      final result = await _pointRepository.createPoint(data);
      
      // Инвалидируем кеш
      await _invalidatePointCache();
      
      return result;
    } catch (e) {
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
      
      // Инвалидируем кеш
      await _invalidatePointCache(id);
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePoint(int id) async {
    try {
      final result = await _pointRepository.deletePoint(id);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
      
      // Инвалидируем кеш
      await _invalidatePointCache(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRating(int pointId, double rating) async {
    try {
      if (rating < 0 || rating > 5) {
        throw Exception('Некорректный ID');
      }
      
      final result = await _pointRepository.updateRating(pointId, rating);
      if (result == null) {
        throw Exception('Точка не найдена');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePointCategories(int pointId, List<int> categoryIds) async {
    try {
      await _pointRepository.updatePointCategories(pointId, categoryIds);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointReview>> getPointReviews(int pointId) async {
    try {
      return await _pointRepository.getPointReviews(pointId);
    } catch (e) {
      rethrow;
    }
  }

  Future<PointReview> createPointReview(Map<String, dynamic> data) async {
    try {
      final result = await _pointRepository.createPointReview(data);
      return result;
    } catch (e) {
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

  /// Инвалидация кеша точек
  Future<void> _invalidatePointCache([int? pointId]) async {
    try {
      if (pointId != null) {
        // Удаляем конкретную точку
        await _cacheService.delete(CacheKeys.point(pointId));
      }
      
      // Удаляем списки точек (они могут измениться)
      await _cacheService.delete(CacheKeys.allPoints());
      await _cacheService.deleteByPattern('points:category:*');
      await _cacheService.deleteByPattern('points:city:*');
      await _cacheService.deleteByPattern('points:partner:*');
    } catch (e) {
      // Не пробрасываем ошибку, так как это не критично
    }
  }
} 