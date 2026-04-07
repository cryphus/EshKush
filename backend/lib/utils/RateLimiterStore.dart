/// Абстракция хранилища для rate limiter.
///
/// Позволяет использовать разные бэкенды:
///   - [InMemoryRateLimiterStore] — по умолчанию, один инстанс
///   - Любая реализация на Redis (напр. через resp_client) для нескольких инстансов
abstract class RateLimiterStore {
  /// Увеличивает счётчик запросов для [key] и возвращает текущее количество
  /// запросов в окне [window]. Если запись устарела — сбрасывает счётчик.
  Future<int> increment(String key, Duration window);

  /// Освобождает ресурсы (закрывает соединение и т.п.).
  Future<void> close() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// In-Memory реализация (один инстанс / тесты)
// ─────────────────────────────────────────────────────────────────────────────

class InMemoryRateLimiterStore implements RateLimiterStore {
  // Для каждого ключа хранится список меток времени запросов в текущем окне.
  final Map<String, List<DateTime>> _windows = {};

  @override
  Future<int> increment(String key, Duration window) async {
    final now = DateTime.now();
    final times = _windows[key]?.where((t) => now.difference(t) < window).toList() ?? [];
    times.add(now);
    _windows[key] = times;
    return times.length;
  }

  @override
  Future<void> close() async => _windows.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// Redis-ready интерфейс (для нескольких инстансов)
//
// Чтобы активировать:
//   1. Добавить в pubspec.yaml зависимость: resp_client: ^0.4.0  (или redis: ^3.x)
//   2. Раскомментировать import ниже
//   3. Раскомментировать класс RedisRateLimiterStore
//   4. В Service.dart: заменить InMemoryRateLimiterStore() на RedisRateLimiterStore(...)
//
// import 'package:resp_client/resp_client.dart';
// import 'package:resp_client/resp_commands.dart';
//
// class RedisRateLimiterStore implements RateLimiterStore {
//   final RespCommands _redis;
//   RedisRateLimiterStore(this._redis);
//
//   @override
//   Future<int> increment(String key, Duration window) async {
//     final count = await _redis.incr(key);
//     if (count == 1) {
//       // Первый запрос в окне — устанавливаем TTL
//       await _redis.expire(key, window.inSeconds);
//     }
//     return count;
//   }
//
//   static Future<RedisRateLimiterStore> connect(String host, int port, {String? password}) async {
//     final client = await RespClient.connect(host, port);
//     final commands = RespCommands(client);
//     if (password != null && password.isNotEmpty) {
//       await commands.auth(password);
//     }
//     return RedisRateLimiterStore(commands);
//   }
//
//   @override
//   Future<void> close() async => _redis.client.close();
// }