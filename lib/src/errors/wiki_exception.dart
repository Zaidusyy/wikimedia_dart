/// The full Wikimedia Dart exception hierarchy.
///
/// [WikiException] is a [sealed] class — this enables exhaustive
/// `switch` expressions in consumer code. The Dart 3 compiler will warn
/// if a new subtype is added but not handled in an exhaustive switch.
///
/// All subtypes are `final` — consumers should not subclass them.
///
/// ```dart
/// try {
///   final summary = await wiki.pages.summary('Earth');
/// } on WikiNotFoundException catch (e) {
///   print('Not found: ${e.message}');
/// } on WikiRateLimitException catch (e) {
///   final wait = e.retryAfter ?? const Duration(seconds: 5);
///   print('Rate limited — retry after ${wait.inSeconds}s');
/// } on WikiException catch (e) {
///   print('Wikimedia Dart error: ${e.message}');
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

/// A network-level failure — DNS resolution, socket error, or loss of
/// connectivity.
///
/// Wraps [http.ClientException] from `package:http`.
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

/// The server returned a 5xx error.
final class WikiServerException extends WikiException {
  /// Creates a [WikiServerException].
  const WikiServerException({
    required super.message,
    required this.statusCode,
  });

  /// The HTTP status code returned by the server.
  final int statusCode;
}

/// The API response could not be deserialised into the expected model.
///
/// This usually indicates an upstream Wikimedia API schema change.
final class WikiParseException extends WikiException {
  /// Creates a [WikiParseException].
  const WikiParseException({required super.message, super.cause});
}
