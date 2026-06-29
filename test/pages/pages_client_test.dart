import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';
import '../test_helpers.dart';

void main() {
  group('PagesClient', () {
    test('summary() returns PageSummary on 200', () async {
      final mockResponse = fixture('responses/page_summary_earth.json');
      final mock = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        expect(request.url.path, '/api/rest_v1/page/summary/Earth');
        expect(request.method, 'GET');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final summary = await wiki.pages.summary('Earth');

      expect(summary.title, 'Earth');
      expect(summary.displayTitle, contains('Earth'));
      expect(summary.pageId, 9228);
      expect(summary.language, 'en');
      expect(summary.description, 'Third planet from the Sun');
      expect(summary.extract, startsWith('Earth is the third planet'));
      expect(summary.thumbnail, isNotNull);
      expect(summary.thumbnail!.source,
          startsWith('https://upload.wikimedia.org'));
      expect(summary.contentUrls, isNotNull);
      expect(summary.contentUrls!.desktopUrl,
          'https://en.wikipedia.org/wiki/Earth');
    });

    test('summary() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'title': 'Not found'}),
          404,
          headers: {'content-type': 'application/problem+json'},
        );
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('DoesNotExist'),
        throwsA(isA<WikiNotFoundException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having(
                (e) => e.message, 'message', contains('Resource not found'))),
      );
    });

    test(
        'summary() throws WikiRateLimitException on 429 with Retry-After header',
        () async {
      final mock = MockClient((request) async {
        return http.Response(
          'Rate limit exceeded',
          429,
          headers: {
            'retry-after': '30',
          },
        );
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiRateLimitException>()
            .having(
                (e) => e.retryAfter, 'retryAfter', const Duration(seconds: 30))
            .having(
                (e) => e.message, 'message', contains('Rate limit exceeded'))),
      );
    });

    test('summary() throws WikiNetworkException on ClientException', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiNetworkException>().having(
            (e) => e.message, 'message', contains('Connection failed'))),
      );
    });

    test('summary() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<WikiServerException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', contains('Server error 500'))),
      );
    });

    test('html() returns raw HTML body string on 200', () async {
      const mockHtml = '<!DOCTYPE html><html><body>Earth</body></html>';
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/rest_v1/page/html/Earth');
        return http.Response(mockHtml, 200, headers: {
          'content-type': 'text/html; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final html = await wiki.pages.html('Earth');
      expect(html, mockHtml);
    });

    test('related() returns List<PageSummary> on 200', () async {
      final mockResponse =
          fixture('responses/page_related_earth_contract.json');
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/rest_v1/page/related/Earth');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final related = await wiki.pages.related('Earth');

      expect(related, isNotEmpty);
      expect(related.first.title, 'Outer_space');
      expect(related.first.displayTitle, contains('Outer space'));
    });

    test('User-Agent header is sent on every request', () async {
      String? capturedAgent;
      final mockResponse = fixture('responses/page_summary_earth.json');
      final mock = MockClient((request) async {
        capturedAgent = request.headers['user-agent'];
        return http.Response(mockResponse, 200);
      });

      final wiki = WikiClient.wikipedia(
        userAgent: 'WikimediaDartTestAgent/1.0',
        httpClient: mock,
      );
      await wiki.pages.summary('Earth');
      expect(capturedAgent, 'WikimediaDartTestAgent/1.0');
    });

    test('html() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.html('Earth'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('html() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.html('Earth'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('related() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.related('Earth'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('related() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.related('Earth'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('related() throws WikiParseException on invalid JSON structure',
        () async {
      final mock = MockClient((request) async {
        return http.Response('{"pages": "not-a-list"}', 200);
      });
      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.pages.related('Earth'),
        throwsA(isA<WikiParseException>()),
      );
    });

    test('throws StateError when client is closed', () async {
      final mock = MockClient((request) async => http.Response('{}', 200));
      final wiki = WikiClient.wikipedia(httpClient: mock);
      wiki.close();

      expect(
        () => wiki.pages.summary('Earth'),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('closed'))),
      );
    });
  });
}
