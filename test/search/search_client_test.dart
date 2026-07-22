import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';
import '../test_helpers.dart';

void main() {
  group('SearchClient', () {
    test('pages() returns SearchResponse on 200', () async {
      final mockResponse = fixture('responses/search_climate_change.json');
      final mock = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        expect(request.url.path, '/w/rest.php/v1/search/page');
        expect(request.url.queryParameters['q'], 'climate change');
        expect(request.url.queryParameters['limit'], '3');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final response = await wiki.search.pages('climate change', limit: 3);

      expect(response.pages, isNotEmpty);
      expect(response.pages.length, 3);

      final first = response.pages.first;
      expect(first.title, 'Climate change');
      expect(first.pageId, 5042951);
      expect(first.description, 'Human-caused changes to climate on Earth');
      expect(first.excerpt,
          contains('Present-day <span class="searchmatch">climate</span>'));
      expect(first.thumbnail, isNotNull);
      expect(first.thumbnail!.source,
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Change_in_Average_Temperature_With_Fahrenheit.svg/60px-Change_in_Average_Temperature_With_Fahrenheit.svg.png');
      expect(first.thumbnail!.width, 60);
      expect(first.thumbnail!.height, 54);
    });

    test('pages() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Resource not found', 404);
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.search.pages('climate change'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('pages() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final wiki = WikiClient.wikipedia(
        httpClient: mock,
        retryPolicy: const RetryPolicy.none(),
      );
      expect(
        () => wiki.search.pages('climate change'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('autocomplete() returns List<String> on 200', () async {
      const mockResponse = '''
      {
        "pages": [
          {"id": 9228, "key": "Earth", "title": "Earth"},
          {"id": 10582, "key": "Earthquake", "title": "Earthquake"}
        ]
      }
      ''';

      final mock = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        expect(request.url.path, '/w/rest.php/v1/search/title');
        expect(request.url.queryParameters['q'], 'Ear');
        expect(request.url.queryParameters['limit'], '5');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final suggestions = await wiki.search.autocomplete('Ear', limit: 5);

      expect(suggestions, equals(['Earth', 'Earthquake']));
    });

    test('autocomplete() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Resource not found', 404);
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.search.autocomplete('Ear'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('autocomplete() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final wiki = WikiClient.wikipedia(
        httpClient: mock,
        retryPolicy: const RetryPolicy.none(),
      );
      expect(
        () => wiki.search.autocomplete('Ear'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('throws StateError when client is closed', () async {
      final mock = MockClient((request) async => http.Response('{}', 200));
      final wiki = WikiClient.wikipedia(httpClient: mock);
      wiki.close();

      expect(
        () => wiki.search.pages('Ear'),
        throwsStateError,
      );
      expect(
        () => wiki.search.autocomplete('Ear'),
        throwsStateError,
      );
    });
  });
}
