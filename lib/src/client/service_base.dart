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
              message: 'Request timed out after ${_describe(config.timeout)}',
              uri: uri,
            ),
          );
      return await handleResponse(response, parser);
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
              message: 'Request timed out after ${_describe(config.timeout)}',
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
  ///
  /// A client closed mid-call stops retrying and rethrows the last failure,
  /// so nothing is sent after [WikiClient.close].
  Future<T> _withRetry<T>(Uri uri, Future<T> Function() attempt) async {
    final policy = config.retryPolicy;
    var retries = 0;
    while (true) {
      try {
        return await attempt();
      } on WikiException catch (e) {
        if (isClosed || retries >= policy.maxRetries || !isRetryable(e)) {
          rethrow;
        }
        final backoff = policy.backoffFor(retries, retryAfter: retryAfterOf(e));
        await Future<void>.delayed(backoff);
        if (isClosed) rethrow;
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
      200 => parse(_utf8Body(response), parser),
      404 => throw WikiNotFoundException(
          message: 'Resource not found at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: 404,
          uri: url,
        ),
      429 => () {
          final retryAfter = parseRetryAfter(response);
          final seconds = retryAfter?.inSeconds;
          final suffix = seconds != null ? ' (retry after ${seconds}s)' : '';
          throw WikiRateLimitException(
            message: 'Rate limit exceeded$suffix${_reason(response)}',
            retryAfter: retryAfter,
          );
        }(),
      >= 500 => throw WikiServerException(
          message: 'Server error $statusCode at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: statusCode,
          retryAfter: parseRetryAfter(response),
        ),
      >= 400 => throw WikiRequestException(
          message: 'Request rejected ($statusCode) at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: statusCode,
        ),
      _ => throw WikiServerException(
          message:
              'Unexpected status code: $statusCode at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
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
          message: 'Resource not found at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: 404,
          uri: url,
        ),
      429 => () {
          final retryAfter = parseRetryAfter(response);
          final seconds = retryAfter?.inSeconds;
          final suffix = seconds != null ? ' (retry after ${seconds}s)' : '';
          throw WikiRateLimitException(
            message: 'Rate limit exceeded$suffix${_reason(response)}',
            retryAfter: retryAfter,
          );
        }(),
      >= 500 => throw WikiServerException(
          message: 'Server error $statusCode at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: statusCode,
          retryAfter: parseRetryAfter(response),
        ),
      >= 400 => throw WikiRequestException(
          message: 'Request rejected ($statusCode) at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: statusCode,
        ),
      _ => throw WikiServerException(
          message:
              'Unexpected status code: $statusCode at URL: ${url ?? "unknown"}'
              '${_reason(response)}',
          statusCode: statusCode,
        ),
    };
  }

  /// The body of a JSON response as text.
  ///
  /// JSON is always UTF-8, but the core REST endpoints (search, title search)
  /// send `application/json` with no charset, and http releases before 1.4.0
  /// decode that as latin1. Decoding the bytes ourselves keeps non-ASCII text
  /// intact on every http version this package allows.
  String _utf8Body(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException catch (e) {
      throw WikiParseException(
        message: 'Response is not valid UTF-8: ${e.message}',
        cause: e,
      );
    }
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

/// [d] in whole seconds when it is a whole number of them, otherwise in
/// milliseconds, so a 1500ms timeout isn't reported as 1s.
String _describe(Duration d) =>
    d.inMilliseconds % 1000 == 0 ? '${d.inSeconds}s' : '${d.inMilliseconds}ms';

/// The server's explanation from an error response, formatted as a message
/// suffix, or '' when the body has nothing useful (empty, or an HTML page).
///
/// MediaWiki's REST errors carry the reason as JSON (`messageTranslations`,
/// `message`, or RESTBase's `detail`/`title`); Wikimedia's edge sends some
/// rejections, such as a missing User-Agent, as plain text.
String _reason(http.Response response) {
  final text = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
  String? reason;
  if (text.startsWith('{')) {
    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) {
        final translations = json['messageTranslations'];
        final candidates = [
          if (translations is Map) translations['en'],
          json['message'],
          json['detail'],
          json['title'],
        ].whereType<String>();
        if (candidates.isNotEmpty) reason = candidates.first;
      }
    } on FormatException {
      // Not JSON after all; nothing reliable to show.
    }
  } else if (!text.startsWith('<')) {
    reason = text;
  }
  if (reason == null) return '';
  reason = reason.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (reason.isEmpty) return '';
  if (reason.length > 200) reason = '${reason.substring(0, 200)}...';
  return ' (server said: $reason)';
}
