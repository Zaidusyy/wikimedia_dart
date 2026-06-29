import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';
import '../test_helpers.dart';

void main() {
  group('WikiException hierarchy', () {
    test('WikiNetworkException is a WikiException', () {
      const e = WikiNetworkException(message: 'connection refused');
      expect(e, isA<WikiException>());
      expect(e, isA<Exception>());
      expect(e.message, 'connection refused');
      expect(e.uri, isNull);
      expect(e.cause, isNull);
    });

    test('WikiTimeoutException is a WikiException', () {
      const e = WikiTimeoutException(message: 'timed out');
      expect(e, isA<WikiException>());
      expect(e.message, 'timed out');
      expect(e.uri, isNull);
    });

    test('WikiNotFoundException carries statusCode and uri', () {
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/DoesNotExist');
      final e = WikiNotFoundException(
        message: 'Resource not found',
        statusCode: 404,
        uri: uri,
      );
      expect(e, isA<WikiException>());
      expect(e.statusCode, 404);
      expect(e.uri, uri);
    });

    test('WikiRateLimitException carries retryAfter', () {
      const e = WikiRateLimitException(
        message: 'Rate limit exceeded',
        retryAfter: Duration(seconds: 30),
      );
      expect(e, isA<WikiException>());
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('WikiRateLimitException retryAfter can be null', () {
      const e = WikiRateLimitException(message: 'Rate limit exceeded');
      expect(e.retryAfter, isNull);
    });

    test('WikiServerException carries statusCode', () {
      const e = WikiServerException(
        message: 'Internal server error',
        statusCode: 500,
      );
      expect(e, isA<WikiException>());
      expect(e.statusCode, 500);
    });

    test('WikiParseException is a WikiException with cause', () {
      const cause = FormatException('bad json');
      const e = WikiParseException(
        message: 'Failed to parse',
        cause: cause,
      );
      expect(e, isA<WikiException>());
      expect(e.cause, same(cause));
    });

    test('toString includes runtimeType and message', () {
      const e = WikiNetworkException(message: 'no route to host');
      expect(e.toString(), contains('WikiNetworkException'));
      expect(e.toString(), contains('no route to host'));
    });
  });

  group('WikiClient integration and lifecycle', () {
    test('named constructors initialize with correct configurations', () {
      final wiki = WikiClient.wikipedia(language: 'fr');
      expect(wiki.pages, isNotNull);
      wiki.close();

      final wiktionary = WikiClient.wiktionary(language: 'de');
      expect(wiktionary.search, isNotNull);
      wiktionary.close();

      final commonsClient = WikiClient.commons();
      expect(commonsClient.media, isNotNull);
      commonsClient.close();

      final customClient =
          WikiClient.custom(baseUrl: 'https://wiki.example.org');
      expect(customClient.pages, isNotNull);
      customClient.close();
    });

    test('WikiClient owns default http.Client and closes it', () {
      final wiki = WikiClient.wikipedia();
      wiki.close();
    });

    test('end-to-end integration summary request', () async {
      final mockResponse = fixture('responses/page_summary_earth.json');
      final mock = MockClient((request) async {
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final summary = await wiki.pages.summary('Earth');
      expect(summary.title, 'Earth');
      expect(summary.pageId, 9228);
      wiki.close();
    });

    test('close is safe to call multiple times', () {
      final wiki = WikiClient.wikipedia();
      wiki.close();
      expect(() => wiki.close(), returnsNormally);
    });

    test('post-close service calls throw StateError', () {
      final wiki = WikiClient.wikipedia();
      wiki.close();
      expect(() => wiki.pages.summary('Earth'), throwsStateError);
      expect(() => wiki.search.pages('Earth'), throwsStateError);
      expect(() => wiki.media.listForPage('Earth'), throwsStateError);
    });
  });

  group('Exception messages runtime context', () {
    test('WikiNotFoundException message contains URL', () async {
      final mock = MockClient((request) async {
        return http.Response('Not Found', 404, request: request);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiNotFoundException>().having(
          (e) => e.message,
          'message',
          contains(
              'Resource not found at URL: https://en.wikipedia.org/api/rest_v1/page/summary/Earth'),
        )),
      );
      wiki.close();
    });

    test('WikiRateLimitException message contains retry after info', () async {
      final mock = MockClient((request) async {
        return http.Response('Rate limit', 429, headers: {
          'retry-after': '45',
        });
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiRateLimitException>().having(
          (e) => e.message,
          'message',
          contains('Rate limit exceeded (retry after 45s)'),
        )),
      );
      wiki.close();
    });

    test('WikiServerException message contains status code and URL', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 503, request: request);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiServerException>().having(
          (e) => e.message,
          'message',
          contains(
              'Server error 503 at URL: https://en.wikipedia.org/api/rest_v1/page/summary/Earth'),
        )),
      );
      wiki.close();
    });

    test(
        'WikiServerException teapot message contains unexpected status code and URL',
        () async {
      final mock = MockClient((request) async {
        return http.Response('Teapot', 418, request: request);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiServerException>().having(
          (e) => e.message,
          'message',
          contains(
              'Unexpected status code: 418 at URL: https://en.wikipedia.org/api/rest_v1/page/summary/Earth'),
        )),
      );
      wiki.close();
    });
  });
}
