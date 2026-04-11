import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Слушает события Connectivity и эмитит true, когда сеть отсутствует.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  late final StreamController<bool> controller;
  StreamSubscription? sub;

  controller = StreamController<bool>(
    onListen: () async {
      // Начальное состояние
      final initial = await connectivity.checkConnectivity();
      controller.add(_isOffline(initial));
      sub = connectivity.onConnectivityChanged.listen((result) {
        if (!controller.isClosed) controller.add(_isOffline(result));
      });
    },
    onCancel: () async {
      await sub?.cancel();
    },
  );

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
});

bool _isOffline(ConnectivityResult result) => result == ConnectivityResult.none;
