// Условный экспорт: используем веб-версию на веб-платформе, заглушку на остальных
export 'VKAuthService_stub.dart'
    if (dart.library.html) 'VKAuthService_web.dart';
