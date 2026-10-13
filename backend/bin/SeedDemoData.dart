import 'dart:io';
import 'dart:math';
import 'package:postgres/postgres.dart';
import 'package:bcrypt/bcrypt.dart';

/// Сидирует демо-данные для ручного тестирования приложения:
/// города (Тюмень, Ялуторовск), партнёры, точки с реальными координатами,
/// продукты, категории, промокоды, демо-пользователь с профилем.
///
/// Идемпотентен — безопасен для многократного запуска.
///
/// Запуск с хоста (Postgres из docker-compose проброшен на 5433):
///   DB_HOST=localhost DB_PORT=5433 DB_NAME=eshkush DB_USER=postgres \
///   DB_PASSWORD=... dart run bin/SeedDemoData.dart
Future<void> main() async {
  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '5433') ?? 5433;
  final dbName = Platform.environment['DB_NAME'] ?? 'eshkush';
  final dbUser = Platform.environment['DB_USER'] ?? 'postgres';
  final dbPass = Platform.environment['DB_PASSWORD'] ?? '';

  final conn = PostgreSQLConnection(host, port, dbName,
      username: dbUser, password: dbPass);
  await conn.open();

  try {
    // Startup must preserve changes made during a presentation.
    final count = await conn.query('SELECT COUNT(*) FROM points');
    final reset = Platform.environment['DEMO_MODE'] == 'true' && Platform.environment['DEMO_RESET'] == 'true';
    if ((count.first.first as int) > 0 && !reset) {
      print('[seed] Existing catalog preserved');
      return;
    }
    // ── Пользователи ─────────────────────────────────────────────────────────
    final demoId = await _ensureUser(
      conn,
      username: 'demo',
      password: 'Demo@1234',
      email: 'demo@eshkush.test',
      number: '+79000000001',
      role: 'user',
      firstName: 'Демо',
      lastName: 'Пользователь',
    );
    final partnerUserId = await _ensureUser(
      conn,
      username: 'partner1',
      password: 'Partner@1234',
      email: 'partner@eshkush.test',
      number: '+79000000002',
      role: 'partner',
      firstName: 'Партнёр',
      lastName: 'Тестовый',
    );
    final adminId = await _ensureUser(
      conn,
      username: 'adminuser',
      password: 'Admin@1234',
      email: 'admin@eshkush.test',
      number: '+79000000000',
      role: 'admin',
      firstName: 'Админ',
      lastName: 'Главный',
    );
    print('[seed] users: demo=$demoId, partner1=$partnerUserId, admin=$adminId');

    // ── Сброс демо-точек/партнёров/продуктов ─────────────────────────────────
    // Раньше сид использовал вымышленные заведения («Хлебник», «Васаби» и т.д.).
    // Теперь используются реальные заведения Тюмени и Ялуторовска (ниже),
    // поэтому старые записи удаляются: CASCADE подчищает точки, продукты,
    // заказы, отзывы и связи категорий — пользователи/города/категории целы.
    await conn.execute(
        'TRUNCATE partners, points, products RESTART IDENTITY CASCADE');

    // ── Профиль демо-пользователя ────────────────────────────────────────────
    await conn.execute('''
      INSERT INTO profiles (user_id, first_name, last_name, bio, sum_co2, saved_money, count_buy)
      SELECT @userId, 'Демо', 'Пользователь', 'Спасаю еду вместе с EshKush', 12, 840.50, 7
      WHERE NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = @userId)
    ''', substitutionValues: {'userId': demoId});

    // ── Города ───────────────────────────────────────────────────────────────
    final tyumenId = await _ensureCity(conn, 'Тюмень');
    final yalutorovskId = await _ensureCity(conn, 'Ялуторовск');
    print('[seed] cities: Тюмень=$tyumenId, Ялуторовск=$yalutorovskId');

    // ── Партнёры ─────────────────────────────────────────────────────────────
    // Реальные заведения Тюмени и Ялуторовска (адреса и координаты проверены
    // через OpenStreetMap Nominatim). Каждое заведение — отдельный партнёр,
    // все привязаны к тестовому аккаунту partner1 для демо-входа.
    final biskvitDvorId = await _ensurePartner(
        conn, partnerUserId, 'БулоШная & Бисквитный двор',
        email: 'biskvit@eshkush.test');
    final bakeUpId = await _ensurePartner(conn, partnerUserId, 'Bake Up',
        email: 'bakeup@eshkush.test');
    final sushiMasterId = await _ensurePartner(
        conn, partnerUserId, 'Суши Мастер',
        email: 'sushimaster@eshkush.test');
    final bistroId = await _ensurePartner(conn, partnerUserId, 'The БИСТРО',
        email: 'bistro@eshkush.test');
    final maximId = await _ensurePartner(conn, partnerUserId, 'Максим',
        email: 'maxim@eshkush.test');
    final breadberryId = await _ensurePartner(conn, partnerUserId, 'Breadберри',
        email: 'breadberry@eshkush.test');
    final vselennayaId = await _ensurePartner(
        conn, partnerUserId, 'Вселенная вкуса',
        email: 'vselennaya@eshkush.test');

    // ── Категории точек ──────────────────────────────────────────────────────
    final pointCats = <String, int>{};
    for (final name in [
      'Пекарни',
      'Кондитерские',
      'Суши',
      'Пицца',
      'Кофейни',
      'Кафе',
    ]) {
      pointCats[name] = await _ensureNamed(conn, 'point_categories', name);
    }

    // ── Категории продуктов ──────────────────────────────────────────────────
    final productCats = <String, int>{};
    for (final name in [
      'Выпечка',
      'Десерты',
      'Суши и роллы',
      'Пицца',
      'Напитки',
      'Комбо-наборы',
    ]) {
      productCats[name] = await _ensureNamed(conn, 'product_categories', name);
    }

    // ── Точки ────────────────────────────────────────────────────────────────
    // Реальные заведения. Координаты получены геокодированием точных адресов
    // через OpenStreetMap Nominatim (nominatim.openstreetmap.org), поэтому
    // маркеры на карте (OSM) указывают на настоящие здания.
    final points = <Map<String, dynamic>>[
      {
        'name': 'БулоШная & Бисквитный двор',
        'address': 'г. Тюмень, ул. Пермякова, 88',
        'city': tyumenId,
        'partner': biskvitDvorId,
        'lat': 57.1067997, 'lon': 65.5627428,
        'open': '08:00', 'close': '22:00',
        'rating': 4.8,
        'tags': '{"пекарни": true, "выпечка": true, "торты": true}',
        'category': 'Пекарни',
        // Реальное фото с Яндекс.Карт (CDN отдаёт CORS-заголовки; в отличие
        // от tumen.biskvitdvor.ru — там Image.network не грузился под
        // Flutter Web/CanvasKit из-за отсутствия Access-Control-Allow-Origin).
        'image': 'https://avatars.mds.yandex.net/get-altay/10804279/2a00000191a84510a661968bead795afcfd6/XXL_height',
      },
      {
        'name': 'Bake Up',
        'address': 'г. Тюмень, ул. Челюскинцев, 36',
        'city': tyumenId,
        'partner': bakeUpId,
        'lat': 57.1568661, 'lon': 65.5337800,
        'open': '07:30', 'close': '22:00',
        'rating': 4.7,
        'tags': '{"кофейни": true, "напитки": true, "выпечка": true}',
        'category': 'Кофейни',
        // Реальное фото с официального сайта (bakeup-tyumen.ru).
        'image': 'https://static.tildacdn.com/tild6332-3132-4362-a531-313165663831/tempImageYIBzLB_1-3.png',
      },
      {
        'name': 'Суши Мастер',
        'address': 'г. Тюмень, Ямская ул., 102',
        'city': tyumenId,
        'partner': sushiMasterId,
        'lat': 57.1593526, 'lon': 65.4883421,
        'open': '11:00', 'close': '23:00',
        'rating': 4.6,
        'tags': '{"суши": true, "роллы": true}',
        'category': 'Суши',
        // Реальное фото с карточки заведения в Яндекс.Картах.
        'image': 'https://avatars.mds.yandex.net/get-altay/15413593/2a00000197d5a41add78e2de8c9a160d701f/L_height',
      },
      {
        'name': 'The БИСТРО',
        'address': 'г. Тюмень, ул. Республики, 148',
        'city': tyumenId,
        'partner': bistroId,
        'lat': 57.1359949, 'lon': 65.5722603,
        'open': '10:00', 'close': '23:00',
        'rating': 4.8,
        'tags': '{"пицца": true, "семейная кухня": true}',
        'category': 'Пицца',
        // Реальное фото с карточки заведения в Яндекс.Картах.
        'image': 'https://avatars.mds.yandex.net/get-altay/5097872/2a000001815ce54e3f3dc393c372c3d4282c/L_height',
      },
      {
        'name': 'Кофейня «Максим»',
        'address': 'г. Тюмень, ул. Республики, 24',
        'city': tyumenId,
        'partner': maximId,
        'lat': 57.1579926, 'lon': 65.5303635,
        'open': '08:00', 'close': '22:00',
        'rating': 4.7,
        'tags': '{"кондитерские": true, "десерты": true, "завтраки": true}',
        'category': 'Кондитерские',
        // Реальное фото с Яндекс.Карт (CDN отдаёт CORS-заголовки; в отличие
        // от visittyumen.ru — там Image.network не грузился под Flutter
        // Web/CanvasKit из-за отсутствия Access-Control-Allow-Origin).
        'image': 'https://avatars.mds.yandex.net/get-altay/4398559/2a0000018ca0200c2e29313503df9136ee16/XXL_height',
      },
      // Ялуторовск
      {
        'name': 'Breadберри',
        'address': 'г. Ялуторовск, ул. Красноармейская, 27',
        'city': yalutorovskId,
        'partner': breadberryId,
        'lat': 56.6574761, 'lon': 66.3124020,
        'open': '09:00', 'close': '21:00',
        'rating': 4.6,
        'tags': '{"пекарни": true, "выпечка": true}',
        'category': 'Пекарни',
        // Реальное фото сети Breadberry (франшиза, не именно этот филиал —
        // отдельного фото Ялуторовского филиала в открытом доступе нет).
        'image': 'https://static.tildacdn.com/tild6133-3834-4632-a666-366662386265/_1.jpg',
      },
      {
        'name': 'Вселенная вкуса',
        'address': 'г. Ялуторовск, ул. Ленина, 15',
        'city': yalutorovskId,
        'partner': vselennayaId,
        'lat': 56.6519067, 'lon': 66.3172336,
        'open': '09:00', 'close': '22:00',
        'rating': 4.5,
        'tags': '{"кафе": true, "домашняя кухня": true}',
        'category': 'Кафе',
        // Для этого заведения не нашлось стабильной прямой ссылки на
        // реальное фото — используется обобщённое (но настоящее) фото
        // уютного семейного кафе с Wikimedia Commons.
        'image':
            'https://upload.wikimedia.org/wikipedia/commons/f/f6/Cozy_Corner_Cafe-_Mishicot%2C_WI_-_Flickr_-_MichaelSteeber.jpg',
      },
    ];

    final pointIds = <String, int>{};
    for (final p in points) {
      final id = await _ensurePoint(conn, p);
      pointIds[p['name'] as String] = id;
      final catId = pointCats[p['category']];
      if (catId != null) {
        await conn.execute('''
          INSERT INTO point_category_map (point_id, category_id)
          VALUES (@pointId, @catId)
          ON CONFLICT DO NOTHING
        ''', substitutionValues: {'pointId': id, 'catId': catId});
      }
    }
    print('[seed] points: ${pointIds.length}');

    // ── Продукты ─────────────────────────────────────────────────────────────
    // Позиции подобраны под реальный профиль каждого заведения (кухня,
    // собственное производство и т.д. по открытым описаниям заведений).
    final products = <Map<String, dynamic>>[
      // БулоШная & Бисквитный двор — сеть кондитерских пекарен: торты,
      // выпечка, свежий хлеб собственного производства. Точка закрывается
      // в 22:00 — самовывоз в последние ~1.5 часа перед закрытием.
      {'point': 'БулоШная & Бисквитный двор', 'partner': biskvitDvorId, 'name': 'Бокс «Вечерняя выпечка»', 'desc': 'Сюрприз-набор из круассанов, булочек и слоек, испечённых сегодня. Забирайте перед закрытием со скидкой 60%.', 'price': 249.0, 'originalPrice': 620.0, 'weight': 800.0, 'cat': 'Выпечка', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 5},
      {'point': 'БулоШная & Бисквитный двор', 'partner': biskvitDvorId, 'name': 'Хлеб ремесленный (2 шт.)', 'desc': 'Два свежих хлеба на закваске: бородинский и пшеничный, собственная выпечка.', 'price': 159.0, 'originalPrice': 229.0, 'weight': 900.0, 'cat': 'Выпечка', 'tags': ['Мучное', 'Веган'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 2},
      {'point': 'БулоШная & Бисквитный двор', 'partner': biskvitDvorId, 'name': 'Набор пирожных (5 шт.)', 'desc': 'Эклеры, картошка и медовик — свежие кондитерские изделия дня.', 'price': 299.0, 'originalPrice': 499.0, 'weight': 450.0, 'cat': 'Десерты', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 5},
      {'point': 'БулоШная & Бисквитный двор', 'partner': biskvitDvorId, 'name': 'Торт «Наполеон» (целый)', 'desc': 'Классический бисквитный торт собственного производства. Скидка 50%.', 'price': 449.0, 'originalPrice': 899.0, 'weight': 1000.0, 'cat': 'Десерты', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 1},
      // Bake Up — кофейня-пекарня: кофе и свежая выпечка. Закрытие в 22:00.
      {'point': 'Bake Up', 'partner': bakeUpId, 'name': 'Кофе-бокс + десерт', 'desc': 'Зерновой кофе на вынос 250 г и чизкейк дня из витрины.', 'price': 349.0, 'originalPrice': 539.0, 'weight': 400.0, 'cat': 'Напитки', 'tags': ['Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 2},
      {'point': 'Bake Up', 'partner': bakeUpId, 'name': 'Круассан-бокс ассорти (4 шт.)', 'desc': 'Круассаны классический, миндальный, шоколадный и с ветчиной-сыром — выпечка сегодняшнего дня.', 'price': 279.0, 'originalPrice': 429.0, 'weight': 480.0, 'cat': 'Выпечка', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 4},
      // Суши Мастер — сеть доставки японской кухни. Закрытие в 23:00.
      {'point': 'Суши Мастер', 'partner': sushiMasterId, 'name': 'Сет «Вечерний» (24 шт.)', 'desc': 'Филадельфия, Калифорния и запечённые роллы — со скидкой 55% перед закрытием.', 'price': 649.0, 'originalPrice': 1450.0, 'weight': 1100.0, 'cat': 'Суши и роллы', 'tags': ['Без глютена'], 'pickupStart': '21:30', 'pickupEnd': '23:00', 'itemsCount': 24},
      {'point': 'Суши Мастер', 'partner': sushiMasterId, 'name': 'Поке с лососем', 'desc': 'Свежий поке с лососем, рисом и овощами.', 'price': 289.0, 'originalPrice': 419.0, 'weight': 380.0, 'cat': 'Суши и роллы', 'tags': ['Без глютена'], 'pickupStart': '21:30', 'pickupEnd': '23:00', 'itemsCount': 1},
      // The БИСТРО — семейная пиццерия с собственным производством пельменей. Закрытие в 23:00.
      {'point': 'The БИСТРО', 'partner': bistroId, 'name': 'Пицца дня 35 см', 'desc': 'Маргарита или Пепперони — что осталось из вечерней партии, фирменное тесто.', 'price': 329.0, 'originalPrice': 509.0, 'weight': 750.0, 'cat': 'Пицца', 'tags': ['Мучное'], 'pickupStart': '21:30', 'pickupEnd': '23:00', 'itemsCount': 1},
      {'point': 'The БИСТРО', 'partner': bistroId, 'name': 'Пельмени ручной лепки (700 г)', 'desc': 'Домашние пельмени собственного производства — сегодняшняя лепка.', 'price': 269.0, 'originalPrice': 389.0, 'weight': 700.0, 'cat': 'Комбо-наборы', 'tags': ['Мучное'], 'pickupStart': '21:30', 'pickupEnd': '23:00', 'itemsCount': 1},
      {'point': 'The БИСТРО', 'partner': bistroId, 'name': 'Комбо «Ужин на двоих»', 'desc': 'Пицца 30 см + салат Цезарь + 2 напитка.', 'price': 499.0, 'originalPrice': 769.0, 'weight': 1300.0, 'cat': 'Комбо-наборы', 'tags': ['Мучное'], 'pickupStart': '21:30', 'pickupEnd': '23:00', 'itemsCount': 4},
      // Кофейня «Максим» — гастрокофейня: завтраки, супы, десерты, выпечка. Закрытие в 22:00.
      {'point': 'Кофейня «Максим»', 'partner': maximId, 'name': 'Десерт-бокс дня', 'desc': 'Ассорти авторских десертов и выпечки собственного производства.', 'price': 319.0, 'originalPrice': 489.0, 'weight': 420.0, 'cat': 'Десерты', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 4},
      {'point': 'Кофейня «Максим»', 'partner': maximId, 'name': 'Обед-бокс «Домашний»', 'desc': 'Суп, второе и компот — комплексный обед из сегодняшнего меню со скидкой.', 'price': 219.0, 'originalPrice': 369.0, 'weight': 900.0, 'cat': 'Комбо-наборы', 'tags': ['Халяль'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 3},
      // Breadберри — кафе-пекарня (Ялуторовск). Закрытие в 21:00.
      {'point': 'Breadберри', 'partner': breadberryId, 'name': 'Бокс «Хлебный день»', 'desc': 'Хлеб, батон и сдоба из сегодняшней выпечки.', 'price': 149.0, 'originalPrice': 229.0, 'weight': 1000.0, 'cat': 'Выпечка', 'tags': ['Мучное', 'Веган'], 'pickupStart': '19:30', 'pickupEnd': '21:00', 'itemsCount': 3},
      {'point': 'Breadберри', 'partner': breadberryId, 'name': 'Ватрушки с творогом (4 шт.)', 'desc': 'Домашние ватрушки со свежим творогом собственной выпечки.', 'price': 129.0, 'originalPrice': 189.0, 'weight': 400.0, 'cat': 'Выпечка', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '19:30', 'pickupEnd': '21:00', 'itemsCount': 4},
      // Вселенная вкуса — семейное кафе (Ялуторовск). Закрытие в 22:00.
      {'point': 'Вселенная вкуса', 'partner': vselennayaId, 'name': 'Комплексный обед дня', 'desc': 'Суп, горячее и напиток — комплексный обед со скидкой к вечеру.', 'price': 199.0, 'originalPrice': 309.0, 'weight': 900.0, 'cat': 'Комбо-наборы', 'tags': ['Халяль'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 3},
      {'point': 'Вселенная вкуса', 'partner': vselennayaId, 'name': 'Блины со сгущёнкой (8 шт.)', 'desc': 'Тонкие блинчики, приготовлены сегодня.', 'price': 159.0, 'originalPrice': 229.0, 'weight': 480.0, 'cat': 'Десерты', 'tags': ['Мучное', 'Сладкое'], 'pickupStart': '20:30', 'pickupEnd': '22:00', 'itemsCount': 8},
    ];

    var productCount = 0;
    // Собираем id продуктов по точкам — нужны для генерации демо-заказов.
    final productsByPoint = <int, List<Map<String, dynamic>>>{};
    for (final pr in products) {
      final pointId = pointIds[pr['point']];
      if (pointId == null) continue;
      final prodId = await _ensureProduct(conn, pr, pointId);
      if (prodId != null) {
        productCount++;
        productsByPoint
            .putIfAbsent(pointId, () => [])
            .add({'id': prodId, 'price': pr['price']});
        final catId = productCats[pr['cat']];
        if (catId != null) {
          await conn.execute('''
            INSERT INTO product_category_map (product_id, category_id)
            VALUES (@prodId, @catId)
            ON CONFLICT DO NOTHING
          ''', substitutionValues: {'prodId': prodId, 'catId': catId});
        }
      }
    }
    print('[seed] products: $productCount');

    // ── Демо-заказы (для наполнения аналитики партнёра) ─────────────────────
    await _seedOrders(conn, demoId, productsByPoint);

    // ── Отзывы (для рейтинга точек) ─────────────────────────────────────────
    for (final entry in pointIds.entries) {
      await conn.execute('''
        INSERT INTO point_reviews (user_id, point_id, rating, comment)
        SELECT @userId, @pointId, 4.5, 'Отличное место, всё свежее!'
        WHERE NOT EXISTS (
          SELECT 1 FROM point_reviews WHERE user_id = @userId AND point_id = @pointId
        )
      ''', substitutionValues: {'userId': demoId, 'pointId': entry.value});
    }

    // ── Промокод ─────────────────────────────────────────────────────────────
    await conn.execute('''
      INSERT INTO promo_codes (code, description, start_date, end_date,
                               min_order_sum, discount_type, discount_value, is_active)
      SELECT 'WELCOME10', 'Скидка 10% на первый заказ',
             CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 year',
             100, 'percentage', 10, TRUE
      WHERE NOT EXISTS (SELECT 1 FROM promo_codes WHERE code = 'WELCOME10')
    ''');

    // ── Уведомления демо-пользователю ────────────────────────────────────────
    await conn.execute('''
      INSERT INTO notifications (user_id, message, type)
      SELECT @userId, 'Добро пожаловать в EshKush! Спасайте еду со скидкой до 70%.', 'system'
      WHERE NOT EXISTS (
        SELECT 1 FROM notifications WHERE user_id = @userId AND type = 'system'
      )
    ''', substitutionValues: {'userId': demoId});
    await conn.execute('''
      INSERT INTO notifications (user_id, message, type)
      SELECT @userId, 'Промокод WELCOME10 — скидка 10% на первый заказ!', 'promotion'
      WHERE NOT EXISTS (
        SELECT 1 FROM notifications WHERE user_id = @userId AND type = 'promotion'
      )
    ''', substitutionValues: {'userId': demoId});

    print('[seed] Готово. Логин для тестов: demo / Demo@1234');
  } finally {
    await conn.close();
  }
}

Future<int> _ensureUser(
  PostgreSQLConnection conn, {
  required String username,
  required String password,
  required String email,
  required String number,
  required String role,
  String? firstName,
  String? lastName,
}) async {
  final existing = await conn.query(
    'SELECT id FROM users WHERE username = @username',
    substitutionValues: {'username': username},
  );
  if (existing.isNotEmpty) return existing.first[0] as int;

  final cost =
      int.tryParse(Platform.environment['BCRYPT_LOG_ROUNDS'] ?? '10') ?? 10;
  final hash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: cost));
  final rows = await conn.query('''
    INSERT INTO users (username, password, email, number, role, first_name, last_name)
    VALUES (@username, @hash, @email, @number, @role::user_role, @firstName, @lastName)
    RETURNING id
  ''', substitutionValues: {
    'username': username,
    'hash': hash,
    'email': email,
    'number': number,
    'role': role,
    'firstName': firstName,
    'lastName': lastName,
  });
  return rows.first[0] as int;
}

Future<int> _ensureCity(PostgreSQLConnection conn, String name) async {
  final existing = await conn.query(
    'SELECT id FROM cities WHERE name = @name',
    substitutionValues: {'name': name},
  );
  if (existing.isNotEmpty) return existing.first[0] as int;
  final rows = await conn.query(
    'INSERT INTO cities (name) VALUES (@name) RETURNING id',
    substitutionValues: {'name': name},
  );
  return rows.first[0] as int;
}

Future<int> _ensurePartner(PostgreSQLConnection conn, int userId, String name,
    {String? email}) async {
  final existing = await conn.query(
    'SELECT id FROM partners WHERE name = @name',
    substitutionValues: {'name': name},
  );
  if (existing.isNotEmpty) return existing.first[0] as int;
  final rows = await conn.query('''
    INSERT INTO partners (user_id, name, contact_email, max_discount)
    VALUES (@userId, @name, @email, 70.0)
    RETURNING id
  ''', substitutionValues: {'userId': userId, 'name': name, 'email': email});
  return rows.first[0] as int;
}

Future<int> _ensureNamed(
    PostgreSQLConnection conn, String table, String name) async {
  final existing = await conn.query(
    'SELECT id FROM $table WHERE name = @name',
    substitutionValues: {'name': name},
  );
  if (existing.isNotEmpty) return existing.first[0] as int;
  final rows = await conn.query(
    'INSERT INTO $table (name) VALUES (@name) RETURNING id',
    substitutionValues: {'name': name},
  );
  return rows.first[0] as int;
}

Future<int> _ensurePoint(
    PostgreSQLConnection conn, Map<String, dynamic> p) async {
  final existing = await conn.query(
    'SELECT id FROM points WHERE name = @name',
    substitutionValues: {'name': p['name']},
  );
  if (existing.isNotEmpty) return existing.first[0] as int;
  final rows = await conn.query('''
    INSERT INTO points (name, address, rating, city_id, opening_hours,
                        closing_hours, partner_id, longitude, latitude, tags,
                        image_url)
    VALUES (@name, @address, @rating, @cityId, @open, @close,
            @partnerId, @lon, @lat, @tags::jsonb, @imageUrl)
    RETURNING id
  ''', substitutionValues: {
    'name': p['name'],
    'address': p['address'],
    'rating': p['rating'],
    'cityId': p['city'],
    'open': p['open'],
    'close': p['close'],
    'partnerId': p['partner'],
    'lon': p['lon'],
    'lat': p['lat'],
    'tags': p['tags'],
    'imageUrl': Platform.environment['DEMO_MODE'] == 'true' ? '/demo/media/food-${(p['partner'] as int) % 6}.svg' : p['image'],
  });
  return rows.first[0] as int;
}

/// Уникальная demo-фотография КАЖДОГО товара (фото конкретных блюд с
/// Wikimedia Commons — стабильные прямые ссылки, не протухают в отличие от
/// VK/2GIS/Instagram, в отличие от прежней версии не переиспользуются
/// между товарами одной категории).
String _productImageUrl(String name) {
  const productImages = {
    'Бокс «Вечерняя выпечка»':
        'https://upload.wikimedia.org/wikipedia/commons/1/14/Assorted_Pastries_-_Indian.jpg',
    'Хлеб ремесленный (2 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/3/3f/Dark_rye_bread.JPG',
    'Набор пирожных (5 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/a/ad/Chocolate_eclairs_%286792699085%29.jpg',
    'Торт «Наполеон» (целый)':
        'https://upload.wikimedia.org/wikipedia/commons/3/3f/Napoleon_cake_02.JPG',
    'Кофе-бокс + десерт':
        'https://upload.wikimedia.org/wikipedia/commons/5/5b/Plain_New_York-style_cheesecake.JPG',
    'Круассан-бокс ассорти (4 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/3/32/Croissant.jpg',
    'Сет «Вечерний» (24 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/6/60/Sushi_platter.jpg',
    'Поке с лососем':
        'https://upload.wikimedia.org/wikipedia/commons/1/13/Salmon_Poke.jpg',
    'Пицца дня 35 см':
        'https://upload.wikimedia.org/wikipedia/commons/f/f9/Margherita_Pizza.jpg',
    'Пельмени ручной лепки (700 г)':
        'https://upload.wikimedia.org/wikipedia/commons/d/df/Pelmeni_Russian.jpg',
    'Комбо «Ужин на двоих»':
        'https://upload.wikimedia.org/wikipedia/commons/2/23/Caesar_salad_%282%29.jpg',
    'Десерт-бокс дня':
        'https://upload.wikimedia.org/wikipedia/commons/7/77/Assortment_of_desserts.JPG',
    'Обед-бокс «Домашний»':
        'https://upload.wikimedia.org/wikipedia/commons/1/1b/Homemade_chicken_soup.JPG',
    'Бокс «Хлебный день»':
        'https://upload.wikimedia.org/wikipedia/commons/0/05/French_baguette_-_bread_art.jpg',
    'Ватрушки с творогом (4 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/6/6b/Vatrushka_cropped.jpeg',
    'Комплексный обед дня':
        'https://upload.wikimedia.org/wikipedia/commons/0/06/Vegetable_soup.jpg',
    'Блины со сгущёнкой (8 шт.)':
        'https://upload.wikimedia.org/wikipedia/commons/f/f4/Preparation_of_blins_or_blini.jpg',
  };
  return productImages[name] ??
      'https://upload.wikimedia.org/wikipedia/commons/3/32/Croissant.jpg';
}

/// Случайный остаток на складе для demo/теста: 0..29, каждый прогон сида —
/// новое значение (без фиксированного seed). Верхняя граница специально
/// большая, чтобы у точки "как будто" почти неограниченный запас, но
/// изредка (около 1 из 30) товар всё же будет распродан — для проверки
/// UI "раскуплено".
final _stockRandom = Random();
int _randomStockQty() => _stockRandom.nextInt(30);

Future<int?> _ensureProduct(
    PostgreSQLConnection conn, Map<String, dynamic> pr, int pointId) async {
  final existing = await conn.query(
    'SELECT id FROM products WHERE name = @name AND point_id = @pointId',
    substitutionValues: {'name': pr['name'], 'pointId': pointId},
  );
  if (existing.isNotEmpty) {
    final id = existing.first[0] as int;
    // Товар уже засеян раньше (до появления полей original_price/tags/
    // pickup_*/items_count) — доносим эти поля отдельным UPDATE, не трогая
    // цену/остаток.
    await conn.execute('''
      UPDATE products
      SET original_price = @originalPrice, tags = @tags,
          pickup_start = @pickupStart, pickup_end = @pickupEnd,
          items_count = @itemsCount
      WHERE id = @id
    ''', substitutionValues: {
      'id': id,
      'originalPrice': pr['originalPrice'],
      'tags': pr['tags'],
      'pickupStart': pr['pickupStart'],
      'pickupEnd': pr['pickupEnd'],
      'itemsCount': pr['itemsCount'],
    });
    return id;
  }
  final qty = _randomStockQty();
  final rows = await conn.query('''
    INSERT INTO products (name, description, price, image_url, partner_id,
                          point_id, weight, is_available, is_active, quantity,
                          original_price, tags, pickup_start, pickup_end,
                          items_count)
    VALUES (@name, @desc, @price, @imageUrl, @partnerId, @pointId, @weight,
            @isAvailable, TRUE, @quantity, @originalPrice, @tags,
            @pickupStart, @pickupEnd, @itemsCount)
    RETURNING id
  ''', substitutionValues: {
    'name': pr['name'],
    'desc': pr['desc'],
    'price': pr['price'],
    'imageUrl': Platform.environment['DEMO_MODE'] == 'true' ? '/demo/media/food-${pointId % 6}.svg' : _productImageUrl(pr['name'] as String),
    'partnerId': pr['partner'],
    'pointId': pointId,
    'weight': pr['weight'],
    'isAvailable': qty > 0,
    'quantity': qty,
    'originalPrice': pr['originalPrice'],
    'tags': pr['tags'],
    'pickupStart': pr['pickupStart'],
    'pickupEnd': pr['pickupEnd'],
    'itemsCount': pr['itemsCount'],
  });
  return rows.first[0] as int;
}

/// Генерирует демонстрационные заказы за последние 30 дней, чтобы
/// партнёрская аналитика (выручка, продажи, графики) была наполнена.
/// Идемпотентно: если заказы уже есть — ничего не делает.
Future<void> _seedOrders(
  PostgreSQLConnection conn,
  int userId,
  Map<int, List<Map<String, dynamic>>> productsByPoint,
) async {
  final existing = await conn.query('SELECT COUNT(*) FROM orders');
  final count = existing.first[0] as int;
  if (count > 0) {
    print('[seed] orders: пропущено (уже есть $count)');
    return;
  }
  if (productsByPoint.isEmpty) {
    print('[seed] orders: нет продуктов для заказов');
    return;
  }

  final rnd = Random(42); // фиксированный seed — воспроизводимые данные
  final pointIds = productsByPoint.keys.toList();
  var created = 0;

  // ~60 заказов, распределённых по последним 30 дням.
  for (var i = 0; i < 60; i++) {
    final pointId = pointIds[rnd.nextInt(pointIds.length)];
    final catalog = productsByPoint[pointId]!;
    if (catalog.isEmpty) continue;

    // 1–3 позиции в заказе
    final itemCount = 1 + rnd.nextInt(3);
    final chosen = <Map<String, dynamic>>[];
    for (var j = 0; j < itemCount; j++) {
      chosen.add(catalog[rnd.nextInt(catalog.length)]);
    }
    final productIds = chosen.map((c) => c['id'] as int).toList();
    // PostgreSQL-литерал массива: {1,2,3}. Драйвер не мапит Dart List на int[]
    // автоматически, поэтому формируем строку и кастуем в запросе.
    final productIdsLiteral = '{${productIds.join(',')}}';
    final total = chosen.fold<double>(
        0, (s, c) => s + (c['price'] as num).toDouble());

    // Дата в пределах последних 30 дней, вечерние часы (17:00–21:00)
    final daysAgo = rnd.nextInt(30);
    final hour = 17 + rnd.nextInt(5);
    final minute = rnd.nextInt(60);
    final date = DateTime.now()
        .subtract(Duration(days: daysAgo))
        .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);

    // Большинство — выполнены, часть отменена, часть в работе.
    final roll = rnd.nextInt(10);
    final status = roll < 7
        ? 'completed'
        : roll < 9
            ? 'cancelled'
            : 'processing';

    await conn.execute('''
      INSERT INTO orders (user_id, point_id, products_id, date, status, total_price)
      VALUES (@userId, @pointId, @productsId::int[], @date, @status::order_status, @total)
    ''', substitutionValues: {
      'userId': userId,
      'pointId': pointId,
      'productsId': productIdsLiteral,
      'date': date.toUtc(),
      'status': status,
      'total': total,
    });
    created++;
  }
  await conn.execute("""
    INSERT INTO payment_transactions(order_id,provider_transaction_id,order_price,payment_method,status,transaction_date,is_active)
    SELECT id, 'mock-seed-' || id::text, total_price, 'card',
      CASE WHEN status='cancelled' THEN 'refunded'::payment_transaction_status ELSE 'completed'::payment_transaction_status END,
      date, true FROM orders o WHERE o.user_id=@user
      AND NOT EXISTS (SELECT 1 FROM payment_transactions t WHERE t.order_id=o.id)
  """, substitutionValues: {'user': userId});
  print('[seed] orders: $created');
}
