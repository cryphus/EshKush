class Products {
  final int id;
  String name;
  double price;
  double weight;
  int sale;
  final int pointId;
  final String? imageUrl;
  final int partnerId;
  //
  String? description;
  bool isAvailable;
  DateTime? createdAt;
  DateTime? updatedAt;

  Products({
    required this.id,
    required this.name,
    required this.pointId,
    this.description,
    this.price = 0.0,
    this.sale = 0,
    this.weight = 0.0,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    required this.partnerId,
  }) {
    if (price < 0) throw ArgumentError('Price cannot be negative');
    if (weight < 0) throw ArgumentError('Weight cannot be negative');
    if (sale < 0 || sale > 100) throw ArgumentError('Sale must be between 0 and 100');
  }

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['id'] as int,
      name: json['name'] as String,
      pointId: json['pointId'] as int,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      sale: json['sale'] as int,
      weight: (json['weight'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      imageUrl: json['imageUrl'] as String?,
      partnerId: json['partnerId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'weight': weight,
      'sale': sale,
      'pointId': pointId,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'partnerId': partnerId,
    };
  }

  double get finalPrice => price * (1 - sale / 100);
}