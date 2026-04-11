import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/payment_api_service.dart';
import '../models/payment_transaction.dart';

class PaymentState {
  final bool isInitiating;
  final bool isPolling;
  final PaymentTransaction? transaction;
  final String? confirmationUrl;
  final String? error;

  const PaymentState({
    this.isInitiating = false,
    this.isPolling = false,
    this.transaction,
    this.confirmationUrl,
    this.error,
  });

  bool get isCompleted =>
      transaction?.status == PaymentTransactionStatus.completed;
  bool get isFailed =>
      transaction?.status == PaymentTransactionStatus.failed;
  bool get isRefunded =>
      transaction?.status == PaymentTransactionStatus.refunded;

  PaymentState copyWith({
    bool? isInitiating,
    bool? isPolling,
    PaymentTransaction? transaction,
    String? confirmationUrl,
    String? error,
    bool clearError = false,
    bool clearTransaction = false,
  }) {
    return PaymentState(
      isInitiating: isInitiating ?? this.isInitiating,
      isPolling: isPolling ?? this.isPolling,
      transaction:
          clearTransaction ? null : (transaction ?? this.transaction),
      confirmationUrl:
          clearTransaction ? null : (confirmationUrl ?? this.confirmationUrl),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentApiService _api;
  Timer? _pollTimer;

  PaymentNotifier({PaymentApiService? api})
      : _api = api ?? PaymentApiService(),
        super(const PaymentState());

  /// Инициировать оплату: обращается к backend, получает confirmation_url.
  /// Вызывающая сторона сама запускает url_launcher с [state.confirmationUrl].
  Future<bool> initiate({
    required int orderId,
    PaymentMethod paymentMethod = PaymentMethod.card,
    String? description,
  }) async {
    state = state.copyWith(
      isInitiating: true,
      clearError: true,
      clearTransaction: true,
    );
    try {
      final result = await _api.createPayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
        description: description,
      );
      state = state.copyWith(
        isInitiating: false,
        transaction: result.transaction,
        confirmationUrl: result.confirmationUrl,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isInitiating: false, error: e.toString());
      return false;
    }
  }

  /// Запрашивает актуальный статус платежа у backend.
  /// Возвращает true, если статус изменился на финальный (completed/failed/refunded).
  Future<bool> refreshStatus(int orderId) async {
    try {
      final transactions = await _api.getTransactionsByOrder(orderId);
      if (transactions.isEmpty) return false;

      transactions.sort(
          (a, b) => b.transactionDate.compareTo(a.transactionDate));
      final latest = transactions.first;
      state = state.copyWith(transaction: latest, clearError: true);
      return latest.status != PaymentTransactionStatus.pending;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Запускает периодический опрос статуса.
  /// Останавливается автоматически при переходе в финальный статус,
  /// либо по таймауту [maxDuration].
  void startPolling({
    required int orderId,
    Duration interval = const Duration(seconds: 3),
    Duration maxDuration = const Duration(minutes: 10),
  }) {
    stopPolling();
    state = state.copyWith(isPolling: true);
    final deadline = DateTime.now().add(maxDuration);
    _pollTimer = Timer.periodic(interval, (timer) async {
      if (DateTime.now().isAfter(deadline)) {
        stopPolling();
        return;
      }
      final finalized = await refreshStatus(orderId);
      if (finalized) {
        stopPolling();
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (state.isPolling) {
      state = state.copyWith(isPolling: false);
    }
  }

  void reset() {
    stopPolling();
    state = const PaymentState();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final paymentProvider =
    StateNotifierProvider.autoDispose<PaymentNotifier, PaymentState>((ref) {
  final notifier = PaymentNotifier();
  ref.onDispose(notifier.stopPolling);
  return notifier;
});
