import 'dart:io';

void main() async {
  // Получаем путь к Flutter из переменной окружения
  final String? flutterPath = Platform.environment['FLUTTER_ROOT'];
  if (flutterPath == null) {
    print('Ошибка: Переменная окружения FLUTTER_ROOT не найдена');
    print('Пожалуйста, убедитесь что Flutter установлен и добавлен в PATH');
    return;
  }

  final String flutterExecutable = Platform.isWindows 
      ? '$flutterPath\\bin\\flutter.bat'
      : '$flutterPath/bin/flutter';

  // Запускаем сервер
  Process.start('dart', ['service.dart']).then((Process process) {
    process.stdout.transform(const SystemEncoding().decoder).listen(print);
    process.stderr.transform(const SystemEncoding().decoder).listen(print);
    print('Сервер запущен');
  });

  // Запускаем Flutter приложение
  Process.start(flutterExecutable, ['run', '-d', 'chrome']).then((Process process) {
    process.stdout.transform(const SystemEncoding().decoder).listen(print);
    process.stderr.transform(const SystemEncoding().decoder).listen(print);
    print('Flutter приложение запущено');
  });
} 