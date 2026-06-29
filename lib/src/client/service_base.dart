import 'dart:convert';

import 'package:http/http.dart' as http;

import '../client/wiki_config.dart';
import '../errors/wiki_exception.dart';

/// Base mixin shared by all Wikimedia Dart service clients.
///
/// Provides the shared request lifecycle:
/// - Header construction
/// - Timeout with [WikiTimeoutException]
/// - HTTP status → [WikiException] mapping
/// - JSON parsing with [WikiParseException]
///
/// Not part of the public API. Consumers interact only with
/// [PagesClient], [SearchClient], and [MediaClient] via [WikiClient].
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

  /// Performs a GET request and maps the response to [T].
  ///
  /// Handles timeouts, network failures, and status-code-based
  /// exception mapping. All Wikimedia Dart HTTP requests go through here.
  Future<T> get<T>(
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
      return await handleResponse(response, parser);
    } on WikiException {
      // Already a typed Wikimedia Dart error — do not re-wrap.
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

  /// Performs a GET request expecting a raw string response (e.g. HTML).
  Future<String> getRaw(Uri uri) async {
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
