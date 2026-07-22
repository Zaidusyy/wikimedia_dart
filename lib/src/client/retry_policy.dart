import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Controls how transient request failures are retried.
///
/// Attached to every [WikiConfig] and consulted by the shared request
/// lifecycle. Because requests are idempotent `GET`s, retrying is safe. Only
/// failures worth repeating are retried: rate limits (429), 5xx server errors,
/// network failures, and timeouts. A 404, a parse error, or any other 4xx is
/// surfaced right away.
///
/// The wait before each retry is `initialBackoff * backoffMultiplier^n`,
/// capped at [maxBackoff]. If the server sends a `Retry-After` header (on a 429
/// or 503) that value is used instead, also capped at [maxBackoff].
///
/// ```dart
/// const RetryPolicy();        // 3 retries, 500ms then 1s then 2s
/// const RetryPolicy.none();   // no retries
/// ```
@immutable
final class RetryPolicy {
  /// Creates a retry policy.
  ///
  /// [maxRetries] counts the retries *after* the first attempt, so 3 means up
  /// to 4 requests in total. Pass 0 to disable retries. [backoffMultiplier]
  /// must be at least 1.0.
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  })  : assert(maxRetries >= 0, 'maxRetries must be non-negative'),
        assert(
          backoffMultiplier >= 1.0,
          'backoffMultiplier must be at least 1.0',
        );

  /// A policy that never retries; the first failure is thrown straight away.
  const RetryPolicy.none() : this(maxRetries: 0);

  /// How many times to retry after the initial attempt. 0 disables retries.
  final int maxRetries;

  /// Wait before the first retry.
  final Duration initialBackoff;

  /// Ceiling on any single wait, including a server-supplied `Retry-After`.
  final Duration maxBackoff;

  /// Factor the backoff grows by on each successive retry.
  final double backoffMultiplier;

  /// Whether this policy retries at all.
  bool get isEnabled => maxRetries > 0;

  /// The wait before retry number [attempt] (0 for the first retry).
  ///
  /// A [retryAfter] from the server takes precedence over the exponential
  /// schedule, capped at [maxBackoff].
  Duration backoffFor(int attempt, {Duration? retryAfter}) {
    if (retryAfter != null) {
      return retryAfter > maxBackoff ? maxBackoff : retryAfter;
    }
    final scaled =
        initialBackoff.inMilliseconds * math.pow(backoffMultiplier, attempt);
    final capped = math.min(scaled, maxBackoff.inMilliseconds.toDouble());
    return Duration(milliseconds: capped.round());
  }
}
