import 'package:postgres/postgres.dart';
import '../model/entities/Point.dart';
import '../model/entities/PointCategory.dart';
import '../model/entities/PointReview.dart';
import '../model/entities/NearbyPoint.dart';
import 'BaseRepository.dart';

class PointRepository extends BaseRepository {
  PointRepository(PostgreSQLConnection connection) : super(connection);

  Future<List<Point>> findAll({int limit = 20, int offset = 0, int? cityId}) async {
    try {
      final result = await connection.mappedResultsQuery('''
        WITH point_ratings AS (
          SELECT point_id, COALESCE(AVG(rating), 0) as current_rating
          FROM point_reviews
          GROUP BY point_id
        )
        SELECT p.*, COALESCE(pr.current_rating, 0) as rating
        FROM points p
        LEFT JOIN point_ratings pr ON p.id = pr.point_id
        ${cityId != null ? 'WHERE p.city_id = @cityId' : ''}
        ORDER BY p.id
        LIMIT @limit OFFSET @offset
      ''', substitutionValues: {
        'limit': limit,
        'offset': offset,
        if (cityId != null) 'cityId': cityId,
      });

      return result.map((row) => Point.fromJson(row['points']!)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Point?> findById(int id) async {
    try {
      final result = await connection.mappedResultsQuery('''
        WITH point_rating AS (
          SELECT COALESCE(AVG(rating), 0) as current_rating
          FROM point_reviews
          WHERE point_id = @id
        )
        SELECT p.*, pr.current_rating as rating
        FROM points p
        LEFT JOIN point_rating pr ON true
        WHERE p.id = @id
      ''', substitutionValues: {
        'id': id,
      });

      if (result.isEmpty) {
        return null;
      }

      return Point.fromJson(result.first['points']!);
    } catch (e) {
      rethrow;
    }
  }

  /// Поиск точек в радиусе [radiusM] метров вокруг (lat, lon),
  /// отсортированных по возрастанию расстояния.
  /// Использует earthdistance + GIST-индекс (см. init.sql).
  Future<List<NearbyPoint>> findNearby({
    required double lat,
    required double lon,
    required double radiusM,
    int limit = 100,
  }) async {
    try {
      // Используем raw query вместо mappedResultsQuery, чтобы чисто получить
      // distance_m (вычисляемая колонка не группируется под именем таблицы).
      final rows = await connection.query('''
        WITH point_ratings AS (
          SELECT point_id, COALESCE(AVG(rating), 0) as current_rating
          FROM point_reviews
          GROUP BY point_id
        )
        SELECT
          p.id, p.name, p.address,
          COALESCE(pr.current_rating, 0) AS rating,
          p.city_id, p.products, p.opening_hours, p.closing_hours,
          p.partner_id, p.longitude, p.latitude, p.tags,
          p.image_url, p.created_at, p.updated_at,
          earth_distance(
            ll_to_earth(p.latitude::float8, p.longitude::float8),
            ll_to_earth(@lat, @lon)
          ) AS distance_m
        FROM points p
        LEFT JOIN point_ratings pr ON p.id = pr.point_id
        WHERE earth_box(ll_to_earth(@lat, @lon), @radius) @>
              ll_to_earth(p.latitude::float8, p.longitude::float8)
          AND earth_distance(
                ll_to_earth(p.latitude::float8, p.longitude::float8),
                ll_to_earth(@lat, @lon)
              ) <= @radius
        ORDER BY distance_m ASC
        LIMIT @limit
      ''', substitutionValues: {
        'lat': lat,
        'lon': lon,
        'radius': radiusM,
        'limit': limit,
      });

      return rows.map((row) {
        final pointJson = <String, dynamic>{
          'id': row[0],
          'name': row[1],
          'address': row[2],
          'rating': row[3],
          'city_id': row[4],
          'products': row[5],
          'opening_hours': row[6],
          'closing_hours': row[7],
          'partner_id': row[8],
          'longitude': row[9],
          'latitude': row[10],
          'tags': row[11],
          'image_url': row[12],
          'created_at': row[13],
          'updated_at': row[14],
        };
        final distanceM = (row[15] as num?)?.toDouble() ?? 0.0;
        return NearbyPoint(
          point: Point.fromJson(pointJson),
          distanceM: distanceM,
        );
      }).toList();
    } catch (e) {
      print('Ошибка геопоиска точек: $e');
      rethrow;
    }
  }

  Future<List<Point>> findByCategory(int categoryId,
      {int limit = 20, int offset = 0}) async {
    try {
      final results = await connection.mappedResultsQuery('''
        SELECT p.* FROM points p
        JOIN point_category_map pcm ON p.id = pcm.point_id
        WHERE pcm.category_id = @categoryId
        ORDER BY p.id
        LIMIT @limit OFFSET @offset
      ''', substitutionValues: {
        'categoryId': categoryId,
        'limit': limit,
        'offset': offset
      });

      return results.map((row) => Point.fromJson(row['points']!)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointCategory>> getCategoriesForPoint(int pointId) async {
    try {
      final results = await connection.mappedResultsQuery('''
        SELECT c.* FROM point_categories c
        JOIN point_category_map pcm ON c.id = pcm.category_id
        WHERE pcm.point_id = @pointId
      ''', substitutionValues: {'pointId': pointId});

      return results
          .map((row) => PointCategory.fromJson(row['point_categories']!))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Point> createPoint(Map<String, dynamic> data) async {
    try {
      final result = await connection.mappedResultsQuery('''
        INSERT INTO points (
          name, address, city_id, products, opening_hours, 
          closing_hours, partner_id, longitude, latitude, tags,
          created_at
        ) VALUES (
          @name, @address, @city_id, @products, @opening_hours,
          @closing_hours, @partner_id, @longitude, @latitude, @tags,
          CURRENT_TIMESTAMP
        ) RETURNING *
      ''', substitutionValues: {
        'name': data['name'],
        'address': data['address'],
        'city_id': int.parse(data['city_id'].toString()),
        'products': data['products'] ?? {},
        'opening_hours': data['opening_hours'],
        'closing_hours': data['closing_hours'],
        'partner_id': int.parse(data['partner_id'].toString()),
        'longitude': double.parse(data['longitude'].toString()),
        'latitude': double.parse(data['latitude'].toString()),
        'tags': data['tags'] ?? {},
      });

      return Point.fromJson(result.first['points']!);
    } catch (e) {
      rethrow;
    }
  }

  Future<Point?> updatePoint(int id, Map<String, dynamic> data) async {
    try {
      final setClause = data.keys.map((key) => '$key = @$key').join(', ');

      final substitutionValues = <String, dynamic>{
        'id': id,
        ...data,
      };

      final result = await connection.mappedResultsQuery(
        '''
        UPDATE points 
        SET $setClause, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        substitutionValues: substitutionValues,
      );

      if (result.isEmpty) {
        return null;
      }

      return Point.fromJson(result.first['points']!);
    } catch (e) {
      rethrow;
    }
  }

  Future<Point?> deletePoint(int id) async {
    try {
      final result = await connection.mappedResultsQuery(
        'DELETE FROM points WHERE id = @id RETURNING *',
        substitutionValues: {'id': id},
      );

      if (result.isEmpty) {
        return null;
      }

      return Point.fromJson(result.first['points']!);
    } catch (e) {
      rethrow;
    }
  }

  Future<Point?> updateRating(int pointId, double rating) async {
    try {
      final result = await connection.mappedResultsQuery(
        '''
        UPDATE points 
        SET rating = @rating, updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
        RETURNING *
        ''',
        substitutionValues: {
          'id': pointId,
          'rating': rating,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      return Point.fromJson(result.first['points']!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePointCategories(int pointId, List<int> categoryIds) async {
    await connection.transaction((txn) async {
      await txn.mappedResultsQuery(
        'DELETE FROM point_category_map WHERE point_id = @pointId',
        substitutionValues: {'pointId': pointId},
      );

      if (categoryIds.isNotEmpty) {
        await txn.mappedResultsQuery('''
          INSERT INTO point_category_map (point_id, category_id, created_at)
          SELECT @pointId, UNNEST(@categoryIds::int[]), CURRENT_TIMESTAMP
        ''', substitutionValues: {
          'pointId': pointId,
          'categoryIds': categoryIds,
        });
      }
    });
  }

  Future<List<PointReview>> getPointReviews(int pointId) async {
    try {
      final results = await connection.mappedResultsQuery(
        'SELECT * FROM point_reviews WHERE point_id = @pointId ORDER BY created_at DESC',
        substitutionValues: {'pointId': pointId},
      );

      return results
          .map((row) => PointReview.fromJson(row['point_reviews']!))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PointReview> createPointReview(Map<String, dynamic> data) async {
    try {
      final result = await connection.mappedResultsQuery('''
        INSERT INTO point_reviews (
          point_id, user_id, rating, comment, created_at
        ) VALUES (
          @point_id, @user_id, @rating, @comment, CURRENT_TIMESTAMP
        ) RETURNING *
      ''', substitutionValues: {
        'point_id': int.parse(data['point_id'].toString()),
        'user_id': int.parse(data['user_id'].toString()),
        'rating': double.parse(data['rating'].toString()),
        'comment': data['comment'],
      });

      // Обновляем рейтинг точки
      await _updatePointRating(int.parse(data['point_id'].toString()));

      return PointReview.fromJson(result.first['point_reviews']!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _updatePointRating(int pointId) async {
    try {
      await connection.mappedResultsQuery('''
        WITH avg_rating AS (
          SELECT AVG(rating) as new_rating
          FROM point_reviews
          WHERE point_id = @point_id
        )
        UPDATE points
        SET rating = (SELECT new_rating FROM avg_rating),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @point_id
      ''', substitutionValues: {
        'point_id': pointId,
      });
    } catch (e) {
      rethrow;
    }
  }
}
