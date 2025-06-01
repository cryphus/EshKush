class Point {
  final int id;
  final String name;
  String address;
  double rating;
  final int cityId;
  final Map<String, dynamic> products;
  DateTime openingHours;
  DateTime closingHours;
  final int partnerId;
  double longitude;
  double latitude;
  final Map<String, dynamic> tags;
  
  Point({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 0.0,
    required this.cityId,
    required this.products,
    required this.openingHours,
    required this.closingHours,
    required this.partnerId,
    required this.longitude,
    required this.latitude,
    required this.tags,
  });
  
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      cityId: json['cityId'] as int,
      products: json['products'] as Map<String, dynamic>,
      openingHours: DateTime.parse(json['openingHours'] as String),
      closingHours: DateTime.parse(json['closingHours'] as String),
      partnerId: json['partnerId'] as int,
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      tags: json['tags'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'cityId': cityId,
      'products': products,
      'openingHours': openingHours.toIso8601String(),
      'closingHours': closingHours.toIso8601String(),
      'partnerId': partnerId,
      'longitude': longitude,
      'latitude': latitude,
      'tags': tags,
    };
  }
} 
