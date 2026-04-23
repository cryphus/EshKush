import 'package:postgres/postgres.dart';
import 'package:backend/repositories/UserRepository.dart';

/// Фабрика тестовых фикстур для интеграционных тестов репозиториев.
///
/// Все методы возвращают ID созданной записи.
/// Используйте в setUpAll() — не в setUp(), чтобы не пересоздавать
/// родительские данные при каждом тесте.
///
/// Имена генерируются на основе timestamp чтобы избежать коллизий
/// при параллельном запуске нескольких тестовых файлов.
class TestFixtures {
  static int _seq = 0;

  static String _uid() {
    _seq++;
    // Комбинируем микросекунды + счётчик: уникально в рамках одного процесса
    // и практически уникально между параллельными процессами (разные старты).
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '${ts}_$_seq';
  }

  /// Создаёт пользователя через UserRepository (хеширует пароль).
  static Future<int> createUser(
    PostgreSQLConnection conn, {
    String? username,
    String? email,
    String? number,
    String password = 'TestPass1!',
  }) async {
    final uid = _uid();
    final repo = UserRepository(conn);
    final user = await repo.createUser({
      'username': username ?? 'fxuser_$uid',
      'email': email ?? 'fx_$uid@test.com',
      'number': number ?? '+79${_seq.toString().padLeft(9, '0')}',
      'password': password,
      'password_confirm': password,
      'role': 'user',
    });
    return user.id;
  }

  /// Создаёт город прямым SQL-запросом.
  static Future<int> createCity(
    PostgreSQLConnection conn, {
    String name = 'TestCity',
  }) async {
    final result = await conn.query(
      "INSERT INTO cities (name) VALUES (@name) RETURNING id",
      substitutionValues: {'name': name},
    );
    return result.first[0] as int;
  }

  /// Создаёт партнёра прямым SQL-запросом.
  static Future<int> createPartner(
    PostgreSQLConnection conn,
    int userId, {
    String name = 'TestPartner',
  }) async {
    final result = await conn.query(
      '''
      INSERT INTO partners (user_id, name, max_discount, created_at)
      VALUES (@userId, @name, 0.0, CURRENT_TIMESTAMP)
      RETURNING id
      ''',
      substitutionValues: {'userId': userId, 'name': name},
    );
    return result.first[0] as int;
  }

  /// Создаёт точку прямым SQL-запросом.
  static Future<int> createPoint(
    PostgreSQLConnection conn,
    int cityId,
    int partnerId, {
    String name = 'TestPoint',
  }) async {
    final result = await conn.query(
      '''
      INSERT INTO points (
        name, address, city_id, products, opening_hours,
        closing_hours, partner_id, longitude, latitude, tags, created_at
      ) VALUES (
        @name, 'Test Address', @cityId, '{}', '09:00',
        '21:00', @partnerId, 37.6176, 55.7558, '{}', CURRENT_TIMESTAMP
      )
      RETURNING id
      ''',
      substitutionValues: {'name': name, 'cityId': cityId, 'partnerId': partnerId},
    );
    return result.first[0] as int;
  }

  /// Создаёт заказ + платёж атомарно (ORDER + PAYMENT_TRANSACTION).
  static Future<int> createOrder(
    PostgreSQLConnection conn,
    int userId,
    int pointId, {
    List<int> productsId = const [],
    double totalPrice = 100.0,
  }) async {
    late int orderId;
    await conn.transaction((txn) async {
      final orderResult = await txn.query(
        '''
        INSERT INTO orders (user_id, point_id, products_id, date, total_price, status, created_at)
        VALUES (@userId, @pointId, @productsId, CURRENT_TIMESTAMP, @totalPrice, 'pending', CURRENT_TIMESTAMP)
        RETURNING id
        ''',
        substitutionValues: {
          'userId': userId,
          'pointId': pointId,
          'productsId': productsId,
          'totalPrice': totalPrice,
        },
      );
      orderId = orderResult.first[0] as int;

      await txn.query(
        '''
        INSERT INTO payment_transactions (
          order_id, provider_transaction_id, order_price,
          payment_method, status, transaction_date, is_active
        ) VALUES (
          @orderId, @orderId, @totalPrice, 'other', 'pending', CURRENT_TIMESTAMP, true
        )
        ''',
        substitutionValues: {'orderId': orderId, 'totalPrice': totalPrice},
      );
    });
    return orderId;
  }
}
