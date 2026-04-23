/// Утилита для безопасного извлечения полей из Map<String, dynamic>.
///
/// Вместо `data['user_id'] as int` (crash при null или неверном типе) используй:
///   MapUtils.require<int>(data, 'user_id')
class MapUtils {
  MapUtils._();

  /// Возвращает значение [key] из [map], приведённое к типу [T].
  /// Бросает [ArgumentError] если поле отсутствует или равно null.
  /// Бросает [ArgumentError] если тип не совпадает и не может быть приведён.
  static T require<T>(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) {
      throw ArgumentError.notNull('$key');
    }
    if (value is T) return value;

    // Числовые конверсии
    if (T == int && value is String) return int.parse(value) as T;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is String) return double.parse(value) as T;
    if (T == double && value is num) return value.toDouble() as T;

    throw ArgumentError('Поле "$key": ожидался $T, получен ${value.runtimeType}');
  }

  /// Возвращает значение [key] или [defaultValue] если поле отсутствует / null.
  static T getOrDefault<T>(Map<String, dynamic> map, String key, T defaultValue) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is T) return value;

    if (T == int && value is String) return int.parse(value) as T;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is String) return double.parse(value) as T;
    if (T == double && value is num) return value.toDouble() as T;

    return defaultValue;
  }
}