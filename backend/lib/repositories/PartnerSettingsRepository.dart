import 'package:postgres/postgres.dart';
import 'BaseRepository.dart';
import '../model/entities/PartnerSettings.dart';
import '../utils/AppException.dart';

class PartnerSettingsRepository extends BaseRepository {
  PartnerSettingsRepository(PostgreSQLConnection connection)
      : super(connection);

  Future<PartnerSettings?> findById(int id) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          partner_id,
          branding_color,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM partner_settings 
        WHERE id = @id
        ''',
        params: {'id': id},
      );
      return result == null ? null : PartnerSettings.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerSettings?> findByPartnerId(int partnerId) async {
    try {
      final result = await queryOne(
        '''
        SELECT 
          id,
          partner_id,
          branding_color,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM partner_settings 
        WHERE partner_id = @partner_id
        ''',
        params: {'partner_id': partnerId},
      );
      return result == null ? null : PartnerSettings.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerSettings> create(PartnerSettings settings) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO partner_settings (partner_id, branding_color, created_at, updated_at)
        VALUES (@partner_id, @branding_color, @created_at, @updated_at)
        RETURNING 
          id,
          partner_id,
          branding_color,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        ''',
        params: {
          'partner_id': settings.partnerId,
          'branding_color': settings.brandingColor,
          'created_at': settings.createdAt.toIso8601String(),
          'updated_at': settings.updatedAt.toIso8601String(),
        },
      );

      if (result == null) {
        throw const InternalServerException();
      }

      return PartnerSettings.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<PartnerSettings> update(int id, Map<String, dynamic> data) async {
    try {
      if (data['updated_at'] == null) {
        data['updated_at'] = DateTime.now().toIso8601String();
      }

      final result = await queryOne(
        '''
        UPDATE partner_settings 
        SET 
          branding_color = COALESCE(@branding_color, branding_color),
          updated_at = @updated_at
        WHERE id = @id
        RETURNING 
          id,
          partner_id,
          branding_color,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        ''',
        params: {
          'id': id,
          ...data,
        },
      );

      if (result == null) {
        throw const NotFoundException(
            'Р СњР В°РЎРѓРЎвЂљРЎР‚Р С•Р в„–Р С”Р С‘ Р С—Р В°РЎР‚РЎвЂљР Р…Р ВµРЎР‚Р В° Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…РЎвЂ№');
      }
      return PartnerSettings.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM partner_settings WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw const NotFoundException(
            'Р СњР В°РЎРѓРЎвЂљРЎР‚Р С•Р в„–Р С”Р С‘ Р С—Р В°РЎР‚РЎвЂљР Р…Р ВµРЎР‚Р В° Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…РЎвЂ№');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PartnerSettings>> findAll() async {
    try {
      final results = await query('''
        SELECT 
          id,
          partner_id,
          branding_color,
          to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
          to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at
        FROM partner_settings
        ''');
      return results.map((map) => PartnerSettings.fromJson(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
