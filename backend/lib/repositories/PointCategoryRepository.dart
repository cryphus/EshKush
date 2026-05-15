import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/PointCategory.dart';
import '../utils/AppException.dart';

class PointCategoryRepository extends BaseRepository {
  PointCategoryRepository(PostgreSQLConnection connection) : super(connection);

  Future<PointCategory?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          name,
          description,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM point_categories 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null
          ? null
          : PointCategory.fromJson({
              'id': result['id'],
              'name': result['name'] ?? '',
              'description': result['description'],
              'created_at':
                  result['created_at'] ?? DateTime.now().toIso8601String(),
            });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointCategory>> findAll() async {
    try {
      final results = await query('''
        SELECT 
          id,
          name,
          description,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM point_categories
        ''');
      return results
          .map((map) => PointCategory.fromJson({
                'id': map['id'],
                'name': map['name'] ?? '',
                'description': map['description'],
                'created_at':
                    map['created_at'] ?? DateTime.now().toIso8601String(),
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<PointCategory> create(PointCategory category) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO point_categories (name, description, created_at)
        VALUES (@name, @description, @created_at)
        RETURNING 
          id,
          name,
          description,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        ''',
        params: {
          'name': category.name,
          'description': category.description,
          'created_at': category.createdAt.toIso8601String(),
        },
      );

      if (result == null) {
        throw const InternalServerException();
      }

      return PointCategory.fromJson({
        'id': result['id'],
        'name': result['name'] ?? '',
        'description': result['description'],
        'created_at': result['created_at'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<PointCategory> update(int id, Map<String, dynamic> data) async {
    try {
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': id};

      if (data.containsKey('name')) {
        updateFields.add('name = @name');
        params['name'] = data['name'] as String;
      }
      if (data.containsKey('description')) {
        updateFields.add('description = @description');
        params['description'] = data['description'] as String?;
      }

      if (updateFields.isEmpty) {
        throw const BadRequestException();
      }

      final result = await queryOne(
        '''
        UPDATE point_categories 
        SET ${updateFields.join(', ')}
        WHERE id = @id
        RETURNING 
          id,
          name,
          description,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        ''',
        params: params,
      );

      if (result == null) {
        throw const NotFoundException();
      }

      return PointCategory.fromJson({
        'id': result['id'],
        'name': result['name'] ?? '',
        'description': result['description'],
        'created_at': result['created_at'] ?? DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM point_categories WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw const NotFoundException();
      }
    } catch (e) {
      rethrow;
    }
  }
}
