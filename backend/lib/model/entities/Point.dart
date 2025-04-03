import 'package:backend/model/enums/PointCategory.dart';
import 'package:backend/model/enums/City.dart';

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
