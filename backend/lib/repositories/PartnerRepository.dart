import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/Partner.dart';

class PartnerRepository extends BaseRepository {
  final PostgreSQLConnection _connection;

  PartnerRepository(this._connection) : super(_connection);

  Future<Partner?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          user_id,
          name,
          contact_person,
          contact_email,
          contact_phone,
          contact_document,
          max_discount,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM partners 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : Partner.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<Partner> create(Partner partner) async {
    try {
      final result = await queryOne(
        '''
        WITH inserted AS (
          INSERT INTO partners (
            user_id, name, contact_person, contact_email, contact_phone,
            contact_document, max_discount, created_at
          )
          VALUES (
            @user_id, @name, @contact_person, @contact_email, @contact_phone,
            @contact_document, @max_discount, @created_at::timestamp
          )
          RETURNING *
        )
        SELECT 
          id,
          user_id,
          name,
          contact_person,
          contact_email,
          contact_phone,
          contact_document,
          max_discount,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM inserted
        ''',
        params: {
          'user_id': partner.userId,
          'name': partner.name,
          'contact_person': partner.contactPerson,
          'contact_email': partner.contactEmail,
          'contact_phone': partner.contactPhone,
          'contact_document': partner.contactDocument,
          'max_discount': partner.maxDiscount,
          'created_at': partner.createdAt.toIso8601String(),
        },
      );

      if (result == null) {
        throw Exception('Ошибка создания партнера');
      }

      // Добавляем created_at, если его нет в результате
      if (!result.containsKey('created_at')) {
        result['created_at'] = partner.createdAt.toIso8601String();
      }

      return Partner.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<Partner> update(int id, Map<String, dynamic> data) async {
    try {
      // Строим динамический SQL-запрос
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': id};

      if (data.containsKey('name')) {
        updateFields.add('name = @name');
        params['name'] = data['name'];
      }
      if (data.containsKey('contact_person')) {
        updateFields.add('contact_person = @contact_person');
        params['contact_person'] = data['contact_person'];
      }
      if (data.containsKey('contact_email')) {
        updateFields.add('contact_email = @contact_email');
        params['contact_email'] = data['contact_email'];
      }
      if (data.containsKey('contact_phone')) {
        updateFields.add('contact_phone = @contact_phone');
        params['contact_phone'] = data['contact_phone'];
      }
      if (data.containsKey('contact_document')) {
        updateFields.add('contact_document = @contact_document');
        params['contact_document'] = data['contact_document'];
      }
      if (data.containsKey('max_discount')) {
        updateFields.add('max_discount = @max_discount');
        params['max_discount'] = data['max_discount'];
      }

      if (updateFields.isEmpty) {
        throw Exception('Нет полей для обновления');
      }

      final updateQuery = '''
        UPDATE partners 
        SET ${updateFields.join(', ')}
        WHERE id = @id
        RETURNING 
          id,
          user_id,
          name,
          contact_person,
          contact_email,
          contact_phone,
          contact_document,
          max_discount,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
      ''';

      final result = await queryOne(updateQuery, params: params);

      if (result == null) {
        throw Exception('Партнер не найден');
      }

      return Partner.fromJson(result);
    } catch (e) {
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
      rethrow;
    }
  }

  Future<List<Partner>> findAll() async {
    try {
      final results = await query('''
        SELECT 
          id,
          user_id,
          name,
          contact_person,
          contact_email,
          contact_phone,
          contact_document,
          max_discount,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
        FROM partners
        ''');
      return results.map((map) => Partner.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
