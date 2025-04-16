class Profile {
  final int id;
  int sumCO2;
  double savedMoney;
  int countBuy;
  //
  final int userId;
  DateTime createdAt;
  DateTime updatedAt;

  Profile({
    required this.id,
    required this.userId,
    this.savedMoney = 0.0,
    this.countBuy = 0,
    this.sumCO2 = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now() {
    if (savedMoney < 0) throw ArgumentError('Saved money cannot be negative');
    if (sumCO2 < 0) throw ArgumentError('CO2 sum cannot be negative');
    if (countBuy < 0) throw ArgumentError('Purchase count cannot be negative');
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      userId: json['userId'] as int,
      savedMoney: (json['savedMoney'] as num).toDouble(),
      countBuy: json['countBuy'] as int,
      sumCO2: json['sumCO2'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'savedMoney': savedMoney,
      'countBuy': countBuy,
      'sumCO2': sumCO2,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get averageCO2Saved => countBuy > 0 
      ? sumCO2 / countBuy 
      : 0.0;
}