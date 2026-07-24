import 'package:flutter/material.dart';

/// Общие "soft UI" декорации для минималистичного дизайна:
/// мягкие рассеянные тени вместо жёстких бордеров/плоских теней.
class AppShadows {
  static List<BoxShadow> soft({
    double blur = 24,
    double alpha = 0.06,
    Offset offset = const Offset(0, 8),
  }) =>
      [
        BoxShadow(
          color: Colors.black.withValues(alpha: alpha),
          blurRadius: blur,
          offset: offset,
        ),
      ];

  /// Едва заметная тень для мелких элементов (чипы, иконки-кнопки).
  static List<BoxShadow> subtle = soft(blur: 12, alpha: 0.05, offset: const Offset(0, 3));

  /// Тень для крупных карточек (заведения, категории, баннеры).
  static List<BoxShadow> card = soft(blur: 24, alpha: 0.07, offset: const Offset(0, 10));
}
