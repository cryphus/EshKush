import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App Offers',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF0F4E4),
      ),
      home: OffersPage(),
    );
  }
}

class OffersPage extends StatefulWidget {
  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  int _currentIndex = 0;
  static const darkGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFFC8E6C9);

  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Бургерная',
      'rating': '4.8',
      'distance': '1.3 км от вас',
      'time': '19:30 - 21:00',
      'price': '299 ₽',
      'image': 'https://via.placeholder.com/400x200?text=Burger',
      'logo': 'https://via.placeholder.com/50x50?text=B'
    },
    {
      'name': 'Суши Бар',
      'rating': '4.5',
      'distance': '2.1 км от вас',
      'time': '18:00 - 20:30',
      'price': '450 ₽',
      'image': 'https://via.placeholder.com/400x200?text=Sushi',
      'logo': 'https://via.placeholder.com/50x50?text=S'
    },
    {
      'name': 'Пиццерия',
      'rating': '4.7',
      'distance': '0.8 км от вас',
      'time': '20:00 - 22:00',
      'price': '599 ₽',
      'image': 'https://via.placeholder.com/400x200?text=Pizza',
      'logo': 'https://via.placeholder.com/50x50?text=P'
    },
    {
      'name': 'Кофейня',
      'rating': '4.9',
      'distance': '1.5 км от вас',
      'time': '08:00 - 22:00',
      'price': '150 ₽',
      'image': 'https://via.placeholder.com/400x200?text=Coffee',
      'logo': 'https://via.placeholder.com/50x50?text=C'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.black, size: 20),
                const SizedBox(width: 4),
                Text('Тюмень',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            Icon(Icons.shopping_basket, color: darkGreen),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Предложения',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),

            // Первый блок с прямоугольниками
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionBox('Для вас'),
                  _buildActionBox('Карта'),
                  _buildActionBox('Поиск'),
                ],
              ),
            ),

            // Блок с карточками заведений
            ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: restaurants.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildRestaurantCard(restaurants[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBox(String text) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: darkGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black)),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Верхняя часть с изображением
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  data['image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(data['logo'], width: 40, height: 40),
                ),
              ),
            ],
          ),

          // Нижняя часть с информацией
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(data['rating'], style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(data['distance'],
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data['time'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: darkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data['price'],
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
