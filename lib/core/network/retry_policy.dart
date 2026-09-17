import 'dart:math';

/// Max network retries before dead-letter (initial attempt + this many delays).
const int kMaxRetries = 3;

/// Exponential backoff + jitter for queue network retries.
class RetryPolicy {
  RetryPolicy._();

  static Duration backoffDuration(int retryCount) {
    // 2^retryCount seconds + random jitter (0-1000ms)
    final exp = Duration(seconds: 1 << retryCount); // 1s, 2s, 4s
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    return exp + jitter;
  }

  static bool shouldRetry(int retryCount) => retryCount < kMaxRetries;
}
