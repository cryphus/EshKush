import '../enums/user_role.dart';

class User {
  final int id;
  final String username;
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

  bool get isAdmin => role == UserRole.admin;
  bool get isBusiness => role == UserRole.business;
  bool get isSupport => role == UserRole.support;
  bool get isGuest => role == UserRole.guest;
}