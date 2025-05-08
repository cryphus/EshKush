import 'package:postgres/postgres.dart';
import '../model/entities/Partner.dart';

class PartnerRepository {
  final PostgreSQLConnection _connection;

  PartnerRepository(this._connection);

  Future<Map<String, dynamic>?> queryOne(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      if (results.isEmpty) return null;
      return results.first.values.first;
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String query, {Map<String, dynamic>? params}) async {
    try {
      final results = await _connection.mappedResultsQuery(query, substitutionValues: params);
      return results.map((row) => row.values.first).toList();
    } catch (e) {
      print('Ошибка выполнения запроса: $e');
      rethrow;
    }
  }

  Future<Partner?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM partners WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : Partner.fromJson(result);
    } catch (e) {
      print('Ошибка поиска партнера по ID: $e');
      rethrow;
    }
  }

  Future<Partner> create(Partner partner) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO partners (name, contact_person, contact_email, contact_phone, 
                            contact_document, max_discount, created_at)
        VALUES (@name, @contact_person, @contact_email, @contact_phone, 
                @contact_document, @max_discount, @created_at)
        RETURNING *
        ''',
        params: {
          'name': partner.name,
          'contact_person': partner.contactPerson,
          'contact_email': partner.concactEmail,
          'contact_phone': partner.contactPhone,
          'contact_document': partner.contactDocument,
          'max_discount': partner.maxDiscount,
          'created_at': partner.createdAt,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания партнера');
      }
      return Partner.fromJson(result);
    } catch (e) {
      print('Ошибка создания партнера: $e');
      rethrow;
    }
  }

  Future<Partner> update(int id, Map<String, dynamic> data) async {
    try {
      final result = await queryOne(
        '''
        UPDATE partners 
        SET 
          name = COALESCE(@name, name),
          contact_person = COALESCE(@contact_person, contact_person),
          contact_email = COALESCE(@contact_email, contact_email),
          contact_phone = COALESCE(@contact_phone, contact_phone),
          contact_document = COALESCE(@contact_document, contact_document),
          max_discount = COALESCE(@max_discount, max_discount)
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': id,
          ...data,
        },
      );

      if (result == null) {
        throw Exception('Партнер не найден');
      }
      return Partner.fromJson(result);
    } catch (e) {
      print('Ошибка обновления партнера: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM partners WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Партнер не найден');
      }
    } catch (e) {
      print('Ошибка удаления партнера: $e');
      rethrow;
    }
  }

  Future<List<Partner>> findAll() async {
    try {
      final results = await query('SELECT * FROM partners');
      return results.map((map) => Partner.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения списка партнеров: $e');
      rethrow;
    }
  }
} 