
import 'package:backend/model/enums/point_category.dart';
import 'package:backend/model/enums/city.dart';

class Point {
  final int id;
  final String name;
  String address;
  PointCategory category;
  double rating;
  City city;
  
  Point({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    this.rating = 0.0,
    required this.city,
  });

} 