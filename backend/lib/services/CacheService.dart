import '../config/AppConfig.dart';
import '../utils/LoggingUtils.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, Map<String, dynamic>> _cache = {};
  bool _isConnected = false;

  Future<void> initialize() async {
    try {
      final config = AppConfig();
      _isConnected = true;
      await LoggingUtils.logInfo('In-memory кеш инициализирован', context: {
        'host': config.redisHost,
        'port': config.redisPort,
        'db': config.redisDb,
      });
    } catch (e) {
      _isConnected = false;
      await LoggingUtils.logError('Ошибка инициализации кеша', e);
      rethrow;
    }
  }

  bool get isConnected => _isConnected;

  Future<T?> get<T>(String key) async {
    if (!_isConnected) {
      return null;
    }

    try {
      final cached = _cache[key];
      if (cached == null) return null;
      
      final expiresAt = cached['expires_at'] as DateTime?;
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        _cache.remove(key);
        return null;
      }
      
      final value = cached['value'];
      
      if (T == String) return value as T;
      if (T == int) return value as T;
      if (T == double) return value as T;
      if (T == bool) return value as T;
      
      if (value is Map<String, dynamic>) {
        return _deserializeFromJson<T>(value);
      }
      
      return value as T?;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения из кеша: key=$key, type=${T.toString()}', e);
      return null;
    }
  }

  Future<bool> set<T>(String key, T value, {Duration? ttl}) async {
    if (!_isConnected) {
      return false;
    }

    try {
      Map<String, dynamic> serialized;
      
      if (value is String || value is int || value is double || value is bool) {
        serialized = {'value': value};
      } else {
        serialized = _serializeToJson(value);
      }
      
      if (ttl != null) {
        serialized['expires_at'] = DateTime.now().add(ttl);
      }
      
      _cache[key] = serialized;
      await LoggingUtils.logInfo('Сохранено в кеш', context: {'key': key, 'type': T.toString(), 'hasValue': serialized.containsKey('value')});
      return true;
    } catch (e) {
      await LoggingUtils.logError('Ошибка сохранения в кеш: key=$key, type=${T.toString()}', e);
      return false;
    }
  }

  Future<bool> delete(String key) async {
    if (!_isConnected) {
      return false;
    }

    try {
      return _cache.remove(key) != null;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления из кеша', e);
      return false;
    }
  }

  Future<int> deleteByPattern(String pattern) async {
    if (!_isConnected) {
      return 0;
    }

    try {
      final regex = RegExp(pattern.replaceAll('*', '.*'));
      final keysToDelete = _cache.keys.where((key) => regex.hasMatch(key)).toList();
      
      for (final key in keysToDelete) {
        _cache.remove(key);
      }
      
      return keysToDelete.length;
    } catch (e) {
      await LoggingUtils.logError('Ошибка удаления по паттерну', e);
      return 0;
    }
  }

  Future<bool> exists(String key) async {
    if (!_isConnected) {
      return false;
    }

    try {
      final cached = _cache[key];
      if (cached == null) return false;
      
      final expiresAt = cached['expires_at'] as DateTime?;
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        _cache.remove(key);
        return false;
      }
      
      return true;
    } catch (e) {
      await LoggingUtils.logError('Ошибка проверки существования ключа', e);
      return false;
    }
  }

  Future<bool> expire(String key, Duration ttl) async {
    if (!_isConnected) {
      return false;
    }

    try {
      final cached = _cache[key];
      if (cached == null) return false;
      
      cached['expires_at'] = DateTime.now().add(ttl);
      return true;
    } catch (e) {
      await LoggingUtils.logError('Ошибка установки TTL', e);
      return false;
    }
  }

  Future<int> ttl(String key) async {
    if (!_isConnected) {
      return -1;
    }

    try {
      final cached = _cache[key];
      if (cached == null) return -2;
      
      final expiresAt = cached['expires_at'] as DateTime?;
      if (expiresAt == null) return -1;
      
      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : -2;
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения TTL', e);
      return -1;
    }
  }

  Future<bool> flushAll() async {
    if (!_isConnected) {
      return false;
    }

    try {
      _cache.clear();
      return true;
    } catch (e) {
      await LoggingUtils.logError('Ошибка очистки кеша', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    if (!_isConnected) {
      return {};
    }

    try {
      final now = DateTime.now();
      int expired = 0;
      
      for (final cached in _cache.values) {
        final expiresAt = cached['expires_at'] as DateTime?;
        if (expiresAt != null && now.isAfter(expiresAt)) {
          expired++;
        }
      }
      
      return {
        'keyspace': _cache.length,
        'expired_keys': expired,
        'memory_usage': 'in-memory',
        'cache_type': 'memory',
      };
    } catch (e) {
      await LoggingUtils.logError('Ошибка получения статистики кеша', e);
      return {};
    }
  }

  Future<void> close() async {
    try {
      _cache.clear();
      _isConnected = false;
      await LoggingUtils.logInfo('In-memory кеш закрыт');
    } catch (e) {
      await LoggingUtils.logError('Ошибка закрытия кеша', e);
    }
  }

  Map<String, dynamic> _serializeToJson<T>(T value) {
    if (value == null) return {};
    
    if (value is Map<String, dynamic>) {
      return {'value': value};
    }
    
    if (value is String || value is int || value is double || value is bool) {
      return {'value': value};
    }
    
    // Обработка списков
    if (value is List) {
      final jsonList = value.map((item) {
        try {
          final dynamic obj = item;
          return obj.toJson();
        } catch (e) {
          return item.toString();
        }
      }).toList();
      return {'value': jsonList, 'isList': true};
    }
    
    // Обработка объектов с toJson
    try {
      final dynamic obj = value;
      final jsonData = obj.toJson();
      return {'value': jsonData};
    } catch (e) {
      return {'value': value.toString()};
    }
  }

  T? _deserializeFromJson<T>(Map<String, dynamic> json) {
    try {
      if (T == String) return json['value'] as T?;
      if (T == int) return json['value'] as T?;
      if (T == double) return json['value'] as T?;
      if (T == bool) return json['value'] as T?;
      
      // Обработка списков
      if (json['isList'] == true && json['value'] is List) {
        return json['value'] as T?;
      }
      
      // Обработка Map
      if (json['value'] is Map<String, dynamic>) {
        return json['value'] as T?;
      }
      
      if (json.containsKey('value')) {
        return json['value'] as T?;
      }
      
      return json as T?;
    } catch (e) {
      // Игнорируем ошибки десериализации
    }
    
    return null;
  }
}

class CacheKeys {
  static String user(int id) => 'user:$id';
  static String userByEmail(String email) => 'user:email:$email';
  static String userByUsername(String username) => 'user:username:$username';
  static String allUsers() => 'users:all';
  static String usersByRole(String role) => 'users:role:$role';
  
  static String point(int id) => 'point:$id';
  static String allPoints() => 'points:all';
  static String pointsByCategory(int categoryId) => 'points:category:$categoryId';
  static String pointsByCity(int cityId) => 'points:city:$cityId';
  static String pointsByPartner(int partnerId) => 'points:partner:$partnerId';
  
  static String product(int id) => 'product:$id';
  static String allProducts() => 'products:all';
  static String productsByCategory(int categoryId) => 'products:category:$categoryId';
  static String productsByPoint(int pointId) => 'products:point:$pointId';
  static String productsByPartner(int partnerId) => 'products:partner:$partnerId';
  
  static String category(int id) => 'category:$id';
  static String allCategories() => 'categories:all';
  static String pointCategories() => 'categories:points';
  static String productCategories() => 'categories:products';
  
  static String order(int id) => 'order:$id';
  static String userOrders(int userId) => 'orders:user:$userId';
  static String pointOrders(int pointId) => 'orders:point:$pointId';
  
  static String userSession(String token) => 'session:$token';
  static String userSessions(int userId) => 'sessions:user:$userId';
  
  static String jwtToken(String token) => 'jwt:$token';
  static String jwtRefreshToken(String token) => 'jwt:refresh:$token';
  
  static String partnerStats(int partnerId) => 'stats:partner:$partnerId';
  static String pointStats(int pointId) => 'stats:point:$pointId';
  
  static String userPattern() => 'user:*';
  static String pointPattern() => 'point:*';
  static String productPattern() => 'product:*';
  static String orderPattern() => 'order:*';
  static String sessionPattern() => 'session:*';
  static String jwtPattern() => 'jwt:*';
}

class CacheTTL {
  static const Duration user = Duration(minutes: 15);
  static const Duration point = Duration(minutes: 30);
  static const Duration product = Duration(minutes: 30);
  static const Duration category = Duration(hours: 1);
  static const Duration order = Duration(minutes: 10);
  static const Duration session = Duration(hours: 24);
  static const Duration jwt = Duration(minutes: 15);
  static const Duration stats = Duration(minutes: 5);
}