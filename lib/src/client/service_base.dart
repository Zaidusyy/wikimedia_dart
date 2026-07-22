import 'dart:convert';

import 'package:http/http.dart' as http;

import '../client/wiki_config.dart';
import '../errors/wiki_exception.dart';

/// Shared request machinery for the service clients.
///
/// Builds headers, applies the per-request timeout, maps HTTP status codes to
/// a [WikiException], parses JSON, and retries transient failures. Internal:
/// callers reach it through [WikiClient] and its `pages`, `search`, and
/// `media` services.
mixin ServiceBase {
  /// The shared HTTP client. Must be set by the concrete class.
  http.Client get httpClient;

  /// The shared configuration. Must be set by the concrete class.
  WikiConfig get config;

  /// Flag set to `true` after [WikiClient.close] is called.
  bool get isClosed;

  /// Throws a [StateError] if this client has been closed.
  void assertOpen() {
    if (isClosed) {
      throw StateError(
        'WikiClient has been closed. '
        'Create a new WikiClient instance to make further requests.',
      );
    }
  }

  /// Builds the HTTP headers required for every Wikimedia API request.
  Map<String, String> buildHeaders() => {
        'Accept': 'application/json; charset=utf-8',
        'User-Agent': config.userAgent,
      };

  /// GETs [uri] and runs [parser] over the decoded JSON body.
  ///
  /// Every JSON request in the package goes through here, so this is where
  /// timeouts, error mapping, and retries all happen.
  Future<T> get<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parser,
  ) =>
      _withRetry(uri, () => _getOnce(uri, parser));

  /// GETs [uri] and returns the raw response body, e.g. HTML.
  Future<String> getRaw(Uri uri) => _withRetry(uri, () => _getRawOnce(uri));

  Future<T> _getOnce<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await httpClient
          .get(uri, headers: buildHeaders())
          .timeout(
            config.timeout,
            onTimeout: () => throw WikiTimeoutException(
              message: 'Request timed out after ${config.timeout.inSeconds}s',
              uri: uri,
            ),
          );
      return handleResponse(response, parser);
    } on WikiException {
      // Already one of ours; let it through untouched.
      rethrow;
    } on http.ClientException catch (e) {
      throw WikiNetworkException(
        message: e.message,
        cause: e,
        uri: uri,
      );
    } on Exception catch (e) {
      throw WikiNetworkException(
        message: 'Unexpected error: $e',
        cause: e,
        uri: uri,
      );
    }
  }

  Future<String> _getRawOnce(Uri uri) async {
    try {
      final response = await httpClient
          .get(uri, headers: buildHeaders())
          .timeout(
            config.timeout,
            onTimeout: () => throw WikiTimeoutException(
              message: 'Request timed out after ${config.timeout.inSeconds}s',
              uri: uri,
            ),
          );
      return handleRawResponse(response);
    } on WikiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw WikiNetworkException(
        message: e.message,
        cause: e,
        uri: uri,
      );
    } on Exception catch (e) {
      throw WikiNetworkException(
        message: 'Unexpected error: $e',
        cause: e,
        uri: uri,
      );
    }
  }

  /// Executes [attempt], retrying transient failures per the configured
  /// [RetryPolicy]. The last failure is rethrown once retries are exhausted.
  Future<T> _withRetry<T>(Uri uri, Future<T> Function() attempt) async {
    final policy = config.retryPolicy;
    var retries = 0;
    while (true) {
      try {
        return await attempt();
      } on WikiException catch (e) {
        if (retries >= policy.maxRetries || !isRetryable(e)) rethrow;
        final backoff = policy.backoffFor(retries, retryAfter: retryAfterOf(e));
        await Future<void>.delayed(backoff);
        retries++;
      }
    }
  }

  /// Whether [e] represents a transient failure that is safe to retry
  /// for an idempotent `GET`.
  bool isRetryable(WikiException e) => switch (e) {
        WikiRateLimitException() => true,
        WikiNetworkException() => true,
        WikiTimeoutException() => true,
        WikiServerException(:final statusCode) => statusCode >= 500,
        WikiNotFoundException() => false,
        WikiRequestException() => false,
        WikiParseException() => false,
      };

  /// Extracts a server-supplied `Retry-After` duration from [e], if any.
  Duration? retryAfterOf(WikiException e) => switch (e) {
        WikiRateLimitException(:final retryAfter) => retryAfter,
        WikiServerException(:final retryAfter) => retryAfter,
        _ => null,
      };

  /// Maps an HTTP response to [T] or throws the appropriate [WikiException].
  T handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    final url = response.request?.url;
    final statusCode = response.statusCode;

    return switch (statusCode) {
      200 => parse(response.body, parser),
      404 => throw WikiNotFoundException(
          message: 'Resource not found at URL: ${url ?? "unknown"}',
          statusCode: 404,
          uri: url,
        ),
      429 => () {
          final retryAfter = parseRetryAfter(response);
          final seconds = retryAfter?.inSeconds;
          final suffix = seconds != null ? ' (retry after ${seconds}s)' : '';
          throw WikiRateLimitException(
            message: 'Rate limit exceeded$suffix',
            retryAfter: retryAfter,
          );
        }(),
      >= 500 => throw WikiServerException(
          message: 'Server error $statusCode at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
          retryAfter: parseRetryAfter(response),
        ),
      >= 400 => throw WikiRequestException(
          message: 'Request rejected ($statusCode) at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
        ),
      _ => throw WikiServerException(
          message:
              'Unexpected status code: $statusCode at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
        ),
    };
  }

  /// Maps an HTTP response to a raw string or throws a [WikiException].
  String handleRawResponse(http.Response response) {
    final url = response.request?.url;
    final statusCode = response.statusCode;

    return switch (statusCode) {
      200 => response.body,
      404 => throw WikiNotFoundException(
          message: 'Resource not found at URL: ${url ?? "unknown"}',
          statusCode: 404,
          uri: url,
        ),
      429 => () {
          final retryAfter = parseRetryAfter(response);
          final seconds = retryAfter?.inSeconds;
          final suffix = seconds != null ? ' (retry after ${seconds}s)' : '';
          throw WikiRateLimitException(
            message: 'Rate limit exceeded$suffix',
            retryAfter: retryAfter,
          );
        }(),
      >= 500 => throw WikiServerException(
          message: 'Server error $statusCode at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
          retryAfter: parseRetryAfter(response),
        ),
      >= 400 => throw WikiRequestException(
          message: 'Request rejected ($statusCode) at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
        ),
      _ => throw WikiServerException(
          message:
              'Unexpected status code: $statusCode at URL: ${url ?? "unknown"}',
          statusCode: statusCode,
        ),
    };
  }

  /// Decodes JSON and applies [parser], wrapping failures in
  /// [WikiParseException].
  T parse<T>(String body, T Function(Map<String, dynamic>) parser) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return parser(json);
    } catch (e) {
      throw WikiParseException(
        message: 'Failed to parse response: $e',
        cause: e,
      );
    }
  }

  /// Parses the `Retry-After` header value from [response].
  ///
  /// Returns `null` if the header is absent or not an integer.
  Duration? parseRetryAfter(http.Response response) {
    final value = response.headers['retry-after'];
    if (value == null) return null;
    final seconds = int.tryParse(value);
    return seconds != null ? Duration(seconds: seconds) : null;
  }
}
