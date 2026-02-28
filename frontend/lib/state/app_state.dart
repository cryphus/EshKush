import 'package:shared_preferences/shared_preferences.dart';

/// Глобальное состояние приложения — синглтон.
/// Хранит данные об авторизованном пользователе, корзину и статистику.
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // ── Авторизация ─────────────────────────────────────────────────────────────
  String? userName;
  String? userPhone;
  String? userEmail;
  String? userRole; // 'user' | 'partner' | 'admin' | 'support'
  String? accessToken;

  bool get isGuest => userName == null;
  bool get isPartner =>
      userRole == 'partner' || userRole == 'admin' || userRole == 'support';

  // ── Статистика пользователя ─────────────────────────────────────────────────
  double co2Saved = 0.2;
  double moneySaved = 199.0;
  int ordersCount = 1;

  // ── Корзина ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  int get cartCount =>
      _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

  double get cartTotal => _cartItems.fold(0.0, (sum, item) {
        final raw = item['price']?.toString() ?? '0';
        final price = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final qty = item['quantity'] as int? ?? 1;
        return sum + price * qty;
      });

  void addToCart(Map<String, dynamic> product) {
    final idx = _cartItems.indexWhere((i) => i['name'] == product['name']);
    if (idx >= 0) {
      _cartItems[idx]['quantity'] = (_cartItems[idx]['quantity'] as int? ?? 1) + 1;
    } else {
      _cartItems.add({...product, 'quantity': 1});
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
    }
  }

  void updateCartQuantity(int index, int delta) {
    if (index < 0 || index >= _cartItems.length) return;
    final newQty = (_cartItems[index]['quantity'] as int? ?? 1) + delta;
    if (newQty <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index]['quantity'] = newQty;
    }
  }

  void clearCart() => _cartItems.clear();

  // ── История заказов (мок) ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> orderHistory = [
    {
      'id': '1001',
      'pointName': 'БулоШная',
      'date': '12 февр., 19:00',
      'status': 'completed',
      'statusLabel': 'Выполнен',
      'total': '199 ₽',
      'items': ['Хлеб', 'Булочки'],
    },
  ];

  // ── Инициализация из SharedPreferences ──────────────────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
    userName = prefs.getString('user_name');
    userPhone = prefs.getString('user_phone');
    userEmail = prefs.getString('user_email');
    userRole = prefs.getString('user_role');
  }

  // ── Вход ────────────────────────────────────────────────────────────────────
  Future<void> loginWithData({
    required String name,
    String? phone,
    String? email,
    required String role,
    required String token,
  }) async {
    userName = name;
    userPhone = phone;
    userEmail = email;
    userRole = role;
    accessToken = token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_name', name);
    if (phone != null) await prefs.setString('user_phone', phone);
    if (email != null) await prefs.setString('user_email', email);
    await prefs.setString('user_role', role);
  }

  // ── Выход ───────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    userName = null;
    userPhone = null;
    userEmail = null;
    userRole = null;
    accessToken = null;
    _cartItems.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }
}
