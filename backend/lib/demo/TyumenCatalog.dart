import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

/// Curated location metadata and local photography. Existing orders, reviews,
/// prices and stock survive an explicit catalog upgrade.
Future<void> seedTyumenCatalog(PostgreSQLConnection connection) async {
  if (Platform.environment['DEMO_MODE'] != 'true') return;
  final file = File('public/demo/catalog/tyumen.json');
  final catalog = (jsonDecode(await file.readAsString()) as List)
      .cast<Map<String, dynamic>>();
  if (catalog.length != 30) {
    throw StateError('Expected exactly 30 curated Tyumen locations');
  }
  await connection.transaction((db) async {
    final user =
        await db.query("SELECT id FROM users WHERE username='partner1'");
    if (user.isEmpty) throw StateError('Partner account must be seeded first');
    final owner = user.first.first;
    final city = await db.query("SELECT id FROM cities WHERE name='Тюмень'");
    if (city.isEmpty) throw StateError('Tyumen must be seeded first');
    final cityId = city.first.first;
    for (final p in catalog) {
      var partner = await db.query(
          'SELECT id FROM partners WHERE name=@name AND user_id=@owner',
          substitutionValues: {'name': p['brand'], 'owner': owner});
      if (partner.isEmpty) {
        partner = await db.query('''
          INSERT INTO partners(user_id,name,contact_email,max_discount)
          VALUES(@owner,@name,'partner@eshkush.test',70) RETURNING id
        ''', substitutionValues: {'name': p['brand'], 'owner': owner});
      }
      final partnerId = partner.first.first;
      final existing = await db.query('''
        SELECT id FROM points WHERE name=@name OR name=@legacy ORDER BY id LIMIT 1
      ''', substitutionValues: {
        'name': p['name'],
        'legacy': p['legacy_name'] ?? p['name']
      });
      final values = <String, dynamic>{
        'name': p['name'],
        'address': p['address'],
        'city': cityId,
        'partner': partnerId,
        'lat': p['latitude'],
        'lon': p['longitude'],
        'image': p['image'],
        'open': p['opening'],
        'close': p['closing'],
        'rating': p['rating'],
        'tags': jsonEncode({p['category']: true}),
      };
      int pointId;
      if (existing.isNotEmpty) {
        pointId = existing.first.first as int;
        values['id'] = pointId;
        await db.execute('''
          UPDATE points SET name=@name,address=@address,city_id=@city,
            partner_id=@partner,latitude=@lat,longitude=@lon,image_url=@image,
            opening_hours=@open,closing_hours=@close,tags=@tags::jsonb
          WHERE id=@id
        ''', substitutionValues: values);
      } else {
        final created = await db.query('''
          INSERT INTO points(name,address,city_id,partner_id,latitude,longitude,
            image_url,opening_hours,closing_hours,rating,tags)
          VALUES(@name,@address,@city,@partner,@lat,@lon,@image,@open,@close,@rating,@tags::jsonb)
          RETURNING id
        ''', substitutionValues: values);
        pointId = created.first.first as int;
      }
      var category = await db.query(
          'SELECT id FROM point_categories WHERE name=@name',
          substitutionValues: {'name': p['category']});
      if (category.isEmpty) {
        category = await db.query(
            'INSERT INTO point_categories(name) VALUES(@name) RETURNING id',
            substitutionValues: {'name': p['category']});
      }
      await db.execute('''
        INSERT INTO point_category_map(point_id,category_id) VALUES(@point,@category)
        ON CONFLICT DO NOTHING
      ''', substitutionValues: {
        'point': pointId,
        'category': category.first.first
      });
      final products = await db.query(
          'SELECT id,name,image_url FROM products WHERE point_id=@point',
          substitutionValues: {'point': pointId});
      for (final row in products) {
        // Preserve photos uploaded by a partner; replace the old illustrations.
        final oldImage = row[2]?.toString() ?? '';
        if (oldImage.isEmpty ||
            RegExp(r'/demo/media/food-\d+\.svg$').hasMatch(oldImage)) {
          await db.execute(
              'UPDATE products SET image_url=@image,partner_id=@partner WHERE id=@id',
              substitutionValues: {
                'image': foodPhoto(row[1] as String),
                'partner': partnerId,
                'id': row[0]
              });
        } else {
          await db.execute(
              'UPDATE products SET partner_id=@partner WHERE id=@id',
              substitutionValues: {'partner': partnerId, 'id': row[0]});
        }
      }
      // Legacy offer windows must end while this branch is still open.
      final closingHour = int.parse((p['closing'] as String).split(':').first);
      await db.execute('''
        UPDATE products SET
          pickup_end=CASE WHEN pickup_end>@close THEN @close ELSE pickup_end END,
          pickup_start=CASE WHEN pickup_start>=@close THEN @start ELSE pickup_start END,
          weight=CASE WHEN weight>0 AND weight<10 AND image_url LIKE '/demo/media/food-%.jpg'
            THEN weight*1000 ELSE weight END
        WHERE point_id=@point
      ''', substitutionValues: {
        'point': pointId,
        'close': p['closing'],
        'start': '${(closingHour - 1).toString().padLeft(2, '0')}:00',
      });
      if (products.isNotEmpty) continue;
      final offers = _offers[p['category']] ?? _offers['Рестораны']!;
      for (var i = 0; i < offers.length; i++) {
        final offer = offers[i];
        await db.execute('''
          INSERT INTO products(name,description,price,image_url,partner_id,point_id,
            weight,is_available,is_active,quantity,original_price,tags,
            pickup_start,pickup_end,items_count)
          VALUES(@name,@description,@price,@image,@partner,@point,@weight,TRUE,TRUE,
            @quantity,@original,ARRAY['сегодня','выгодно'],'18:00',@close,@items)
        ''', substitutionValues: {
          'name': offer['name'],
          'description': offer['description'],
          'price': offer['price'],
          'original': (offer['price'] as int) * 2,
          'image': foodPhoto(offer['name'] as String),
          'partner': partnerId,
          'point': pointId,
          'weight': (offer['weight'] as num) * 1000,
          'quantity': 4 + (pointId + i) % 9,
          'close': p['closing'],
          'items': offer['items'],
        });
      }
    }
  });
  print('[seed] Tyumen catalog upgraded: 30 locations with local photography');
}

String foodPhoto(String name) {
  final text = name.toLowerCase();
  var image = 0;
  if (RegExp('поке|салат').hasMatch(text)) {
    image = 3;
  } else if (RegExp('суши|ролл|сет').hasMatch(text)) {
    image = 2;
  } else if (text.contains('пицц')) {
    image = 1;
  } else if (RegExp('торт|эклер|пирожн|десерт|чизкейк|кофе').hasMatch(text)) {
    image = 5;
  } else if (RegExp('обед|ужин|суп|пельмен|горяч').hasMatch(text)) {
    image = 4;
  } else if (RegExp('хлеб|багет').hasMatch(text)) {
    image = 6;
  }
  return '/demo/media/food-$image.jpg';
}

const _offers = <String, List<Map<String, Object>>>{
  'Пекарни': [
    {
      'name': 'Бокс «Вечерняя выпечка»',
      'description':
          'Круассаны, слойки и булочки из сегодняшней витрины. Состав зависит от того, что осталось к вечеру.',
      'price': 290,
      'weight': 0.6,
      'items': 4
    },
    {
      'name': 'Хлебный бокс',
      'description':
          'Два ароматных хлеба собственного производства. Для уютного ужина и вкусных завтраков.',
      'price': 190,
      'weight': 0.8,
      'items': 2
    },
  ],
  'Кофейни': [
    {
      'name': 'Кофе-бокс + десерт',
      'description':
          'Кофе на ваш выбор и десерт с витрины. Заберите по пути домой и устройте себе маленький праздник.',
      'price': 250,
      'weight': 0.35,
      'items': 2
    },
    {
      'name': 'Круассан-бокс ассорти',
      'description':
          'Четыре хрустящих круассана: классические и с начинкой. Для себя или чтобы поделиться.',
      'price': 320,
      'weight': 0.4,
      'items': 4
    },
  ],
  'Пицца': [
    {
      'name': 'Пицца дня',
      'description':
          'Пицца на тонком тесте с сыром и начинкой дня. Выбор вкуса уточняйте при получении.',
      'price': 390,
      'weight': 0.65,
      'items': 1
    },
    {
      'name': 'Комбо «Ужин на двоих»',
      'description':
          'Горячее и салат из сегодняшнего меню. Сытный вечер без долгой готовки.',
      'price': 490,
      'weight': 0.8,
      'items': 2
    },
  ],
  'Суши': [
    {
      'name': 'Сет «Вечерний»',
      'description':
          'Ассорти из 24 роллов. В комплекте соевый соус, имбирь и васаби.',
      'price': 590,
      'weight': 0.65,
      'items': 24
    },
    {
      'name': 'Поке с лососем',
      'description':
          'Рис, овощи, лосось и фирменный соус в одной яркой тарелке.',
      'price': 350,
      'weight': 0.4,
      'items': 1
    },
  ],
  'Рестораны': [
    {
      'name': 'Обед-бокс «Домашний»',
      'description':
          'Первое и горячее с гарниром. Сегодняшние блюда для спокойного, вкусного вечера.',
      'price': 340,
      'weight': 0.75,
      'items': 2
    },
    {
      'name': 'Десерт-бокс дня',
      'description':
          'Два десерта от кондитера заведения. Состав меняется каждый день.',
      'price': 290,
      'weight': 0.3,
      'items': 2
    },
  ],
};
