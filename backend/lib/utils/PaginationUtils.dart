import 'package:shelf/shelf.dart';

/// Параметры пагинации, распарсенные из query-строки запроса.
class PaginationParams {
  /// Максимальное количество записей в ответе.
  final int limit;

  /// Смещение (количество пропускаемых записей).
  final int offset;

  const PaginationParams({required this.limit, required this.offset});

  /// Страница (1-based), вычисленная из offset/limit.
  int get page => limit == 0 ? 1 : (offset ~/ limit) + 1;
}

/// Утилита для работы с пагинацией в list-эндпоинтах.
///
/// Поддерживаемые query-параметры:
///   - `limit`  — размер страницы (1–[maxLimit], по умолчанию 20)
///   - `offset` — сдвиг (≥0, по умолчанию 0)
///   - `page`   — альтернатива offset: offset = (page-1) * limit
///
/// Примеры:
///   GET /products?limit=10&offset=20
///   GET /products?limit=10&page=3
class PaginationUtils {
  static const int defaultLimit = 20;
  static const int maxLimit = 100;

  /// Читает limit/offset из query-параметров запроса.
  /// Применяет ограничения: 1 ≤ limit ≤ [maxLimit], offset ≥ 0.
  static PaginationParams parse(Request request, {int max = maxLimit}) {
    final params = request.url.queryParameters;

    final rawLimit = int.tryParse(params['limit'] ?? '') ?? defaultLimit;
    final limit = rawLimit.clamp(1, max);

    int offset;
    if (params.containsKey('page')) {
      final page = (int.tryParse(params['page'] ?? '') ?? 1).clamp(1, 100000);
      offset = (page - 1) * limit;
    } else {
      offset = (int.tryParse(params['offset'] ?? '') ?? 0).clamp(0, 1000000);
    }

    return PaginationParams(limit: limit, offset: offset);
  }

  /// Оборачивает список данных в стандартный пагинированный ответ.
  ///
  /// ```json
  /// {
  ///   "data": [...],
  ///   "pagination": {
  ///     "limit": 20,
  ///     "offset": 0,
  ///     "count": 15,
  ///     "hasMore": false
  ///   }
  /// }
  /// ```
  static Map<String, dynamic> wrap(
    List<dynamic> data,
    PaginationParams params,
  ) {
    return {
      'data': data,
      'pagination': {
        'limit': params.limit,
        'offset': params.offset,
        'count': data.length,
        'hasMore': data.length == params.limit,
      },
    };
  }
}
