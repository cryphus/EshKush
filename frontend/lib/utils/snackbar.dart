import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/colors.dart';

/// Глобальный ключ ScaffoldMessenger — позволяет показывать снэкбары
/// из мест, где нет под рукой BuildContext (interceptors, провайдеры).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum SnackKind { info, success, error }

void showSnack(
  String message, {
  SnackKind kind = SnackKind.info,
  Duration duration = const Duration(seconds: 3),
  BuildContext? context,
}) {
  final messenger = context != null
      ? ScaffoldMessenger.maybeOf(context)
      : rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final Color bg;
  switch (kind) {
    case SnackKind.success:
      bg = AppColors.accentGreen;
      break;
    case SnackKind.error:
      bg = const Color(0xFFD32F2F);
      break;
    case SnackKind.info:
      bg = const Color(0xFF323232);
      break;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Универсальный показ ошибки. Принимает что угодно — пытается
/// извлечь читабельный текст. Для `ApiException` использует его сообщение.
void showApiError(Object error, {BuildContext? context}) {
  final String message;
  if (error is ApiException) {
    message = error.message;
  } else {
    message = error.toString();
  }
  showSnack(message, kind: SnackKind.error, context: context);
}
