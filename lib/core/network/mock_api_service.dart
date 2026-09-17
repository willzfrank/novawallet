import 'dart:math';

/// Local mock API with idempotency + 10% failure.
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

  /// Count of times each key was accepted for processing (first success only increments once).
  final Map<String, int> processAttempts = {};

  int get uniqueProcessedCount => processedKeys.length;

  void reset() {
    processedKeys.clear();
    processAttempts.clear();
  }

  Future<bool> sendMoney(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) {
    return _execute(idempotencyKey, payload);
  }

  Future<bool> contribute(
    Map<String, dynamic> payload,
    String idempotencyKey,
  ) {
    return _execute(idempotencyKey, payload);
  }

  Future<bool> _execute(String idempotencyKey, Map<String, dynamic> payload) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // Duplicate UUID → 200 already processed (success, no reprocess).
    if (processedKeys.contains(idempotencyKey)) {
      // ignore: avoid_print
      print('[MockAPI] duplicate idempotencyKey=$idempotencyKey — already processed');
      return true;
    }

    processAttempts[idempotencyKey] =
        (processAttempts[idempotencyKey] ?? 0) + 1;

    if (_random.nextDouble() < failureRate) {
      // ignore: avoid_print
      print('[MockAPI] FAIL idempotencyKey=$idempotencyKey payload=$payload');
      return false;
    }

    processedKeys.add(idempotencyKey);
    // ignore: avoid_print
    print('[MockAPI] OK idempotencyKey=$idempotencyKey payload=$payload');
    return true;
  }
}
