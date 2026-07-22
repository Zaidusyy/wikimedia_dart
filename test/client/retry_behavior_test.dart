import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

import '../test_helpers.dart';

/// A retry policy with no backoff delay, so behavioural tests run instantly
/// while still exercising the full retry loop.
const _instant = RetryPolicy(initialBackoff: Duration.zero);

void main() {
  group('retry behaviour', () {
    test('retries a 5xx failure then succeeds', () async {
      final summaryJson = fixture('responses/page_summary_earth.json');
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (calls < 3) return http.Response('unavailable', 503);
        return http.Response(summaryJson, 200);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);
      final summary = await wiki.pages.summary('Earth');

      expect(calls, 3, reason: 'two failures + one success');
      expect(summary.title, 'Earth');
    });

    test('retries a 429 rate limit then succeeds', () async {
      final summaryJson = fixture('responses/page_summary_earth.json');
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response('slow down', 429, headers: {'retry-after': '0'});
        }
        return http.Response(summaryJson, 200);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);
      final summary = await wiki.pages.summary('Earth');

      expect(calls, 2);
      expect(summary.title, 'Earth');
    });

    test('retries a network failure then succeeds', () async {
      final summaryJson = fixture('responses/page_summary_earth.json');
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (calls == 1) throw http.ClientException('connection reset');
        return http.Response(summaryJson, 200);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);
      final summary = await wiki.pages.summary('Earth');

      expect(calls, 2);
      expect(summary.title, 'Earth');
    });

    test('exhausts retries and throws the last failure', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('unavailable', 503);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);

      await expectLater(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiServerException>()
            .having((e) => e.statusCode, 'statusCode', 503)),
      );
      expect(calls, 4, reason: 'initial attempt + 3 retries');
    });

    test('does not retry a 404', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('missing', 404);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);

      await expectLater(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiNotFoundException>()),
      );
      expect(calls, 1);
    });

    test('does not retry a non-429 4xx', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('bad request', 400);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);

      await expectLater(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
      expect(calls, 1);
    });

    test('does not retry a parse failure', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('{"pages": "not-a-list"}', 200);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);

      await expectLater(
        () => wiki.pages.related('Earth'),
        throwsA(isA<WikiParseException>()),
      );
      expect(calls, 1);
    });

    test('RetryPolicy.none() disables retries', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('unavailable', 503);
      });

      final wiki = WikiClient.wikipedia(
        httpClient: mock,
        retryPolicy: const RetryPolicy.none(),
      );

      await expectLater(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiServerException>()),
      );
      expect(calls, 1, reason: 'no retries when disabled');
    });

    test('raw (HTML) requests are retried too', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (calls < 2) return http.Response('unavailable', 503);
        return http.Response('<html>Earth</html>', 200);
      });

      final wiki =
          WikiClient.wikipedia(httpClient: mock, retryPolicy: _instant);
      final html = await wiki.pages.html('Earth');

      expect(calls, 2);
      expect(html, contains('Earth'));
    });
  });
}
