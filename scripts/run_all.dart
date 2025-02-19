import 'dart:io';

void main() async {
  final String flutterCommand = Platform.isWindows ? 'flutter.bat' : 'flutter';
  
  try {
    print('Запуск сервера...');
    final server = await Process.start(
      'dart',
      ['backend/bin/service.dart'],
      mode: ProcessStartMode.inheritStdio,
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    print('Запуск Flutter приложения...');
    final flutter = await Process.start(
      flutterCommand,
      ['run', '-d', 'chrome'],
      mode: ProcessStartMode.inheritStdio,
    );

    await Future.wait([
      server.exitCode,
      flutter.exitCode,
    ]);
  } catch (e) {
    print('Ошибка при запуске: $e');
    exit(1);
  }
} 