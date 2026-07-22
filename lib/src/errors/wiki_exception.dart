/// The exception hierarchy thrown by this package.
///
/// [WikiException] is sealed, so a `switch` over it can be checked for
/// completeness at compile time. The subtypes are `final`; don't extend them.
///
/// ```dart
/// try {
///   final summary = await wiki.pages.summary('Earth');
/// } on WikiNotFoundException catch (e) {
///   print('Not found: ${e.message}');
/// } on WikiRateLimitException catch (e) {
///   final wait = e.retryAfter ?? const Duration(seconds: 5);
///   print('Rate limited, retry after ${wait.inSeconds}s');
/// } on WikiException catch (e) {
///   print(e.message);
/// }
/// ```
library;

/// Base class for all exceptions thrown by Wikimedia Dart.
sealed class WikiException implements Exception {
  /// Creates a [WikiException].
  const WikiException({required this.message, this.cause});

  /// Human-readable description of the error.
  final String message;

  /// The underlying exception that caused this error, if any.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// A network-level failure: DNS, socket, or lost connectivity.
///
/// Wraps the underlying `http.ClientException`.
final class WikiNetworkException extends WikiException {
  /// Creates a [WikiNetworkException].
  const WikiNetworkException({
    required super.message,
    super.cause,
    this.uri,
  });

  /// The request URI, if available.
  final Uri? uri;
}

/// The request exceeded the configured [WikiClient] timeout duration.
final class WikiTimeoutException extends WikiException {
  /// Creates a [WikiTimeoutException].
  const WikiTimeoutException({required super.message, this.uri});

  /// The request URI, if available.
  final Uri? uri;
}

/// The requested resource does not exist (HTTP 404).
final class WikiNotFoundException extends WikiException {
  /// Creates a [WikiNotFoundException].
  const WikiNotFoundException({
    required super.message,
    required this.statusCode,
    this.uri,
  });

  /// The HTTP status code (always 404).
  final int statusCode;

  /// The request URI, if available.
  final Uri? uri;
}

/// The API rate limit was exceeded (HTTP 429).
///
/// The [retryAfter] duration is parsed from the `Retry-After` response
/// header when available.
final class WikiRateLimitException extends WikiException {
  /// Creates a [WikiRateLimitException].
  const WikiRateLimitException({
    required super.message,
    this.retryAfter,
  });

  /// Suggested wait time before retrying, or `null` if not specified.
  final Duration? retryAfter;
}

/// The server rejected the request with a 4xx status other than 404 or 429
/// (e.g. 400 Bad Request, 401 Unauthorized, 403 Forbidden).
///
/// These point to a problem with the request itself (a bad title, a removed
/// or restricted endpoint, missing authorization) and are never retried.
final class WikiRequestException extends WikiException {
  /// Creates a [WikiRequestException].
  const WikiRequestException({
    required super.message,
    required this.statusCode,
  });

  /// The 4xx HTTP status code returned by the server.
  final int statusCode;
}

/// The server returned a 5xx error.
final class WikiServerException extends WikiException {
  /// Creates a [WikiServerException].
  const WikiServerException({
    required super.message,
    required this.statusCode,
    this.retryAfter,
  });

  /// The HTTP status code returned by the server.
  final int statusCode;

  /// Suggested wait time before retrying, parsed from the `Retry-After`
  /// response header when present (e.g. on a 503). `null` otherwise.
  final Duration? retryAfter;
}

/// The API response could not be deserialised into the expected model.
///
/// This usually indicates an upstream Wikimedia API schema change.
final class WikiParseException extends WikiException {
  /// Creates a [WikiParseException].
  const WikiParseException({required super.message, super.cause});
}
