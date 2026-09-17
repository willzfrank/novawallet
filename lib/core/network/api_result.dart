/// Result of a MockApi (or future real API) money operation.
sealed class ApiResult {
  const ApiResult();
}

class ApiSuccess extends ApiResult {
  const ApiSuccess();
}

/// Transient / network failure — safe to retry with backoff.
class ApiNetworkError extends ApiResult {
  const ApiNetworkError();
}

/// Business-rule failure — do not retry.
class ApiBusinessError extends ApiResult {
  const ApiBusinessError(this.reason);
  final String reason; // e.g. 'INSUFFICIENT_FUNDS', 'INVALID_RECIPIENT'
}
