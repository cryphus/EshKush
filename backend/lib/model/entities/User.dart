import '../enums/UserRole.dart';

class User {
  final int id;
  String username;
  String password;
  int sumCO2;
  List<String> purchases;
  int money;
  String number;
  String email;
  List<int> favoriteIds;
  UserRole role;
  

  User({
    required this.id,        
    required this.username,  
    required this.password,
    this.sumCO2 = 0,
    this.purchases = const [],
    this.money = 0,
    required this.number,
    required this.email,
    this.favoriteIds = const [],
    this.role = UserRole.user,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      password: map['password'] as String,
      sumCO2: map['sum_co2'] as int? ?? 0,
      purchases: List<String>.from(map['purchases'] as List? ?? []),
      money: map['money'] as int? ?? 0,
      number: map['number'] as String,
      email: map['email'] as String,
      favoriteIds: List<int>.from(map['favorite_ids'] as List? ?? []),
      role: UserRole.values.firstWhere(
        (role) => role.name.toLowerCase() == (map['role'] as String).toLowerCase(),
        orElse: () => UserRole.user,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'sum_co2': sumCO2,
      'purchases': purchases,
      'money': money,
      'number': number,
      'email': email,
      'favorite_ids': favoriteIds,
      'role': role.name.toLowerCase(),
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isBusiness => role == UserRole.business;
  bool get isSupport => role == UserRole.support;
  bool get isGuest => role == UserRole.guest;
}
