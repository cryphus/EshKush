import 'package:postgres/postgres.dart';
import '../model/entities/PromoCodes.dart';
import '../model/enums/DiscountType.dart';

class PromoCodesRepository {
  final PostgreSQLConnection _connection;

  PromoCodesRepository(this._connection);

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

  Future<PromoCodes?> findById(int id) async {
    try {
      final result = await queryOne(
        'SELECT * FROM promo_codes WHERE id = @id',
        params: {'id': id},
      );
      return result == null ? null : PromoCodes.fromJson(result);
    } catch (e) {
      print('Ошибка поиска промокода по ID: $e');
      rethrow;
    }
  }

  Future<PromoCodes?> findByCode(String code) async {
    try {
      final result = await queryOne(
        'SELECT * FROM promo_codes WHERE code = @code',
        params: {'code': code},
      );
      return result == null ? null : PromoCodes.fromJson(result);
    } catch (e) {
      print('Ошибка поиска промокода по коду: $e');
      rethrow;
    }
  }

  Future<List<PromoCodes>> getActivePromoCodes() async {
    try {
      final results = await query(
        '''
        SELECT * FROM promo_codes 
        WHERE is_active = true 
        AND start_date <= CURRENT_TIMESTAMP 
        AND end_date >= CURRENT_TIMESTAMP
        ''',
      );
      return results.map((map) => PromoCodes.fromJson(map)).toList();
    } catch (e) {
      print('Ошибка получения активных промокодов: $e');
      rethrow;
    }
  }

  Future<PromoCodes> create(PromoCodes promoCode) async {
    try {
      final result = await queryOne(
        '''
        INSERT INTO promo_codes (
          code, description, start_date, end_date,
          min_order_sum, discount_type, discount_value,
          is_active, usage_limit, current_usage,
          applicable_products, applicable_points
        )
        VALUES (
          @code, @description, @startDate, @endDate,
          @minOrderSum, @discountType::discount_type, @discountValue,
          @isActive, @usageLimit, @currentUsage,
          @applicableProducts, @applicablePoints
        )
        RETURNING *
        ''',
        params: {
          'code': promoCode.code,
          'description': promoCode.description,
          'startDate': promoCode.startDate,
          'endDate': promoCode.endDate,
          'minOrderSum': promoCode.minOrderSum,
          'discountType': promoCode.discountType.toString().split('.').last,
          'discountValue': promoCode.discountValue,
          'isActive': promoCode.isActive,
          'usageLimit': promoCode.usageLimit,
          'currentUsage': promoCode.currentUsage,
          'applicableProducts': promoCode.applicableProducts,
          'applicablePoints': promoCode.applicablePoints,
        },
      );
      if (result == null) {
        throw Exception('Ошибка создания промокода');
      }
      return PromoCodes.fromJson(result);
    } catch (e) {
      print('Ошибка создания промокода: $e');
      rethrow;
    }
  }

  Future<PromoCodes> update(PromoCodes promoCode) async {
    try {
      final result = await queryOne(
        '''
        UPDATE promo_codes 
        SET 
          description = @description,
          end_date = @endDate,
          min_order_sum = @minOrderSum,
          discount_type = @discountType::discount_type,
          discount_value = @discountValue,
          is_active = @isActive,
          usage_limit = @usageLimit,
          current_usage = @currentUsage,
          applicable_products = @applicableProducts,
          applicable_points = @applicablePoints
        WHERE id = @id
        RETURNING *
        ''',
        params: {
          'id': promoCode.id,
          'description': promoCode.description,
          'endDate': promoCode.endDate,
          'minOrderSum': promoCode.minOrderSum,
          'discountType': promoCode.discountType.toString().split('.').last,
          'discountValue': promoCode.discountValue,
          'isActive': promoCode.isActive,
          'usageLimit': promoCode.usageLimit,
          'currentUsage': promoCode.currentUsage,
          'applicableProducts': promoCode.applicableProducts,
          'applicablePoints': promoCode.applicablePoints,
        },
      );
      if (result == null) {
        throw Exception('Промокод не найден');
      }
      return PromoCodes.fromJson(result);
    } catch (e) {
      print('Ошибка обновления промокода: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final result = await queryOne(
        'DELETE FROM promo_codes WHERE id = @id RETURNING id',
        params: {'id': id},
      );
      if (result == null) {
        throw Exception('Промокод не найден');
      }
    } catch (e) {
      print('Ошибка удаления промокода: $e');
      rethrow;
    }
  }

  Future<void> incrementUsage(int id) async {
    try {
      await queryOne(
        '''
        UPDATE promo_codes 
        SET current_usage = current_usage + 1
        WHERE id = @id AND (usage_limit IS NULL OR current_usage < usage_limit)
        ''',
        params: {'id': id},
      );
    } catch (e) {
      print('Ошибка увеличения счетчика использования: $e');
      rethrow;
    }
  }
} 