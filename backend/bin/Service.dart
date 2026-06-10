import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:backend/database/Database.dart';
import 'package:backend/middleware/CorsMiddleware.dart';
import 'package:backend/services/CacheService.dart';
import 'package:backend/config/AppConfig.dart';
// import 'package:path/path.dart' as p;
// import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:backend/utils/LoggingUtils.dart';
import 'package:backend/bootstrap/AppPipelineFactory.dart';
import 'package:backend/bootstrap/AppRouterFactory.dart';
import 'package:backend/bootstrap/DependencyFactory.dart';

void main() async {
  try {
    final config = AppConfig();
    await config.initialize();

    final cacheService = CacheService();
    await cacheService.initialize();

    final db = await Database.instance;
    final dependencies = await DependencyFactory.create(
      config: config,
      cacheService: cacheService,
      db: db,
    );
    final userSessionRepository = dependencies.userSessionRepository;
    final actionLogService = dependencies.actionLogService;
    final yooKassaService = dependencies.yooKassaService;
    final app = AppRouterFactory.create(dependencies);

    final handler = AppPipelineFactory.create(
      appHandler: app.call,
      userSessionRepository: userSessionRepository,
      actionLogService: actionLogService,
      corsMiddleware: CorsMiddleware(
        allowedOrigins: config.allowedOrigins,
        devMode: config.isDevelopment,
      ),
    );

    final server = await io.serve(handler, '0.0.0.0', config.port);
    await LoggingUtils.logInfo('Сервер запущен',
        context: {'port': server.port});

    if (Platform.environment['RUN_TESTS'] == 'true') {
      _runApiTests();
    }

    final cleanupTimer =
        Timer.periodic(config.sessionCleanupInterval, (_) async {
      try {
        final n = await userSessionRepository.cleanupExpiredSessions();
        await userSessionRepository.cleanupExpiredBlacklist();
        if (n > 0)
          await LoggingUtils.logInfo(
              'Очистка сессий: удалено $n истёкших записей');
      } catch (e, st) {
        await LoggingUtils.logError('Ошибка периодической очистки сессий', e,
            stackTrace: st);
      }
    });

    final shutdownCompleter = Completer<void>();
    var isShuttingDown = false;
    StreamSubscription<ProcessSignal>? sigIntSub;
    StreamSubscription<ProcessSignal>? sigTermSub;

    Future<void> shutdown(String signalName) async {
      if (isShuttingDown) return;
      isShuttingDown = true;
      await LoggingUtils.logInfo(
        'Graceful shutdown started',
        context: {'signal': signalName},
      );

      cleanupTimer.cancel();
      await sigIntSub?.cancel();
      await sigTermSub?.cancel();
      yooKassaService.dispose();

      try {
        await server.close(force: true);
      } catch (_) {}

      try {
        await db.connection.close();
      } catch (_) {}

      if (!shutdownCompleter.isCompleted) {
        shutdownCompleter.complete();
      }
    }

    sigIntSub = ProcessSignal.sigint.watch().listen((_) => shutdown('SIGINT'));
    sigTermSub =
        ProcessSignal.sigterm.watch().listen((_) => shutdown('SIGTERM'));

    await shutdownCompleter.future;
  } catch (e, stackTrace) {
    await LoggingUtils.logError('Ошибка запуска сервера', e,
        stackTrace: stackTrace);
    exit(1);
  }
}

/// Запускает скомпилированный тест-бинарник (Docker) или dart-скрипт (локально).
/// Вызывается асинхронно — сервер не блокируется.
Future<void> _runApiTests() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  print('\n[API Tests] ══════════════════════════════════════════');
  print('[API Tests] Запуск тестов...');

  try {
    final binDir = File(Platform.resolvedExecutable).parent.path;
    final compiled = File('$binDir/api_test');

    late Process proc;
    if (compiled.existsSync()) {
      proc = await Process.start(
        compiled.path,
        [],
        mode: ProcessStartMode.inheritStdio,
      );
    } else {
      final scriptCandidates = [
        '${Directory.current.path}/test/ApiTest.dart',
        '${File(Platform.script.toFilePath()).parent.parent.path}/test/ApiTest.dart',
      ];
      final script = scriptCandidates.firstWhere(
        (p) => File(p).existsSync(),
        orElse: () => '',
      );
      if (script.isEmpty) {
        print('[API Tests] Файл теста не найден. '
            'Ожидается test/ApiTest.dart в корне проекта.');
        return;
      }
      proc = await Process.start(
        'dart',
        ['run', script],
        mode: ProcessStartMode.inheritStdio,
      );
    }

    final code = await proc.exitCode;
    print('[API Tests] Завершено с кодом $code');
    print('[API Tests] ══════════════════════════════════════════\n');
  } catch (e) {
    print('[API Tests] Ошибка запуска тестов: $e');
  }
}
