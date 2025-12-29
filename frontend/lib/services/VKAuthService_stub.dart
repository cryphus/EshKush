import 'dart:async';

// Заглушка для мобильных платформ
// Этот файл используется на Android, iOS и других не-веб платформах

class VKAuthService {
  Future<Map<String, dynamic>?> signIn() async {
    throw UnimplementedError(
      'VK авторизация доступна только на веб-платформе. '
      'Для мобильных устройств используйте другие методы авторизации.',
    );
  }
}

