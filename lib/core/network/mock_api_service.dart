import 'dart:math';

import 'api_result.dart';

/// Local mock API with idempotency + 10% network failure.
class MockApiService {
  MockApiService({
    Random? random,
    this.failureRate = 0.1,
    this.delay = const Duration(seconds: 1),
  }) : _random = random ?? Random();

  final Random _random;
  final double failureRate;
  final Duration delay;

  /// Keys already successfully processed (idempotency store).
  final Set<String> processedKeys = {};

  /// Count of non-duplicate attempts per key (increments on failures too; duplicates skip).
  final Map<String, int> processAttempts = {};

  int get uniqueProcessedCount => processedKeys.length;

  void reset() {
    processedKeys.clear();
    processAttempts.clear();
  }

  Future<ApiResult> sendMoney(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) {
    return _execute(idempotencyKey, payload);
  }

  Future<ApiResult> contribute(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) {
    return _execute(idempotencyKey, payload);
  }

  Future<ApiResult> _execute(
    String idempotencyKey,
    Map<String, dynamic> payload,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // Duplicate UUID → already processed (success, no reprocess).
    if (processedKeys.contains(idempotencyKey)) {
      // ignore: avoid_print
      print(
        '[MockAPI] duplicate idempotencyKey=$idempotencyKey — already processed',
      );
      return const ApiSuccess();
    }

    processAttempts[idempotencyKey] =
        (processAttempts[idempotencyKey] ?? 0) + 1;

    if (payload['forceBusinessError'] == true) {
      // ignore: avoid_print
      print(
        '[MockAPI] BUSINESS_ERROR idempotencyKey=$idempotencyKey payload=$payload',
      );
      return const ApiBusinessError('INSUFFICIENT_FUNDS');
    }

    if (_random.nextDouble() < failureRate) {
      // ignore: avoid_print
      print('[MockAPI] FAIL idempotencyKey=$idempotencyKey payload=$payload');
      return const ApiNetworkError();
    }

    processedKeys.add(idempotencyKey);
    // ignore: avoid_print
    print('[MockAPI] OK idempotencyKey=$idempotencyKey payload=$payload');
    return const ApiSuccess();
  }
}
