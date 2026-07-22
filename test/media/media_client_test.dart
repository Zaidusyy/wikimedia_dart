import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';
import '../test_helpers.dart';

void main() {
  group('MediaClient', () {
    test('listForPage() returns List<MediaItem> on 200', () async {
      final mockResponse = fixture('responses/media_list_earth.json');
      final mock = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        expect(request.url.path, '/api/rest_v1/page/media-list/Earth');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final items = await wiki.media.listForPage('Earth');

      expect(items, isNotEmpty);
      // Let's check some items from the fixture (like the first image).
      final first = items.first;
      expect(first.title, 'File:Meteosat-12-fci-march-equinox-2025-noon.jpg');
      expect(first.type, 'image');
      expect(first.srcUrl, startsWith('https://upload.wikimedia.org/'));
      expect(first.caption, isNull);

      final second = items[1];
      expect(second.title,
          'File:The_Mysterious_Case_of_the_Disappearing_Dust.jpg');
      expect(second.caption, contains('protoplanetary disk'));
    });

    test('listForPage() filters out items lacking a title', () async {
      const mockResponse = '''
      {
        "items": [
          {
            "type": "image",
            "title": "File:ValidImage.jpg",
            "original": {
              "source": "https://upload.wikimedia.org/valid.jpg"
            }
          },
          {
            "type": "image",
            "original": {
              "source": "https://upload.wikimedia.org/math_formula.jpg"
            }
          }
        ]
      }
      ''';

      final mock = MockClient((request) async {
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final items = await wiki.media.listForPage('Earth');

      // The item lacking a title (second one) should be filtered out
      expect(items.length, 1);
      expect(items.first.title, 'File:ValidImage.jpg');
    });

    test('listForPage() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.media.listForPage('Earth'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('listForPage() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final wiki = WikiClient.wikipedia(
        httpClient: mock,
        retryPolicy: const RetryPolicy.none(),
      );
      expect(
        () => wiki.media.listForPage('Earth'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('getFile() returns MediaFile on 200', () async {
      const mockResponse = '''
      {
        "title": "File:Earth.jpg",
        "type": "image",
        "description": "Earth photograph",
        "file_size": 98765,
        "originalimage": {
          "source": "https://upload.wikimedia.org/earth.jpg",
          "width": 800,
          "height": 600
        }
      }
      ''';

      final mock = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        expect(request.url.path, '/api/rest_v1/page/summary/File%3AEarth.jpg');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      final file = await wiki.media.getFile('File:Earth.jpg');

      expect(file.title, 'File:Earth.jpg');
      expect(file.mimeType, 'image');
      expect(file.description, 'Earth photograph');
      expect(file.fileSizeBytes, 98765);
      expect(file.sourceUrl, 'https://upload.wikimedia.org/earth.jpg');
      expect(file.width, 800);
      expect(file.height, 600);
    });

    test('getFile() throws WikiNotFoundException on 404', () async {
      final mock = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final wiki = WikiClient.wikipedia(httpClient: mock);
      expect(
        () => wiki.media.getFile('File:Earth.jpg'),
        throwsA(isA<WikiNotFoundException>()),
      );
    });

    test('getFile() throws WikiServerException on 500', () async {
      final mock = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final wiki = WikiClient.wikipedia(
        httpClient: mock,
        retryPolicy: const RetryPolicy.none(),
      );
      expect(
        () => wiki.media.getFile('File:Earth.jpg'),
        throwsA(isA<WikiServerException>()),
      );
    });

    test('throws StateError when client is closed', () async {
      final mock = MockClient((request) async => http.Response('{}', 200));
      final wiki = WikiClient.wikipedia(httpClient: mock);
      wiki.close();

      expect(
        () => wiki.media.listForPage('Earth'),
        throwsStateError,
      );
      expect(
        () => wiki.media.getFile('File:Earth.jpg'),
        throwsStateError,
      );
    });
  });
}
