// Условный экспорт: используем веб-версию на веб-платформе, заглушку на остальных
export 'vk_auth_service_stub.dart'
    if (dart.library.js_interop) 'vk_auth_service_web.dart';
