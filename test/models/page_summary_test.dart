import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() {
  group('PageSummary', () {
    const minimalJson = <String, dynamic>{
      'title': 'Earth',
      'displaytitle': 'Earth',
      'pageid': 9228,
      'lang': 'en',
    };

    test('fromJson parses required fields', () {
      final summary = PageSummary.fromJson(minimalJson);
      expect(summary.title, 'Earth');
      expect(summary.displayTitle, 'Earth');
      expect(summary.pageId, 9228);
      expect(summary.language, 'en');
    });

    test('fromJson handles all optional fields as null', () {
      final summary = PageSummary.fromJson(minimalJson);
      expect(summary.description, isNull);
      expect(summary.extract, isNull);
      expect(summary.extractHtml, isNull);
      expect(summary.thumbnail, isNull);
      expect(summary.contentUrls, isNull);
      expect(summary.wikidataId, isNull);
      expect(summary.lastModified, isNull);
    });

    test('fromJson parses thumbnail', () {
      final json = {
        ...minimalJson,
        'thumbnail': {
          'source':
              'https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/The_Earth_seen_from_Apollo_17.jpg/320px.jpg',
          'width': 320,
          'height': 320,
        },
      };
      final summary = PageSummary.fromJson(json);
      expect(summary.thumbnail, isNotNull);
      expect(summary.thumbnail!.width, 320);
      expect(summary.thumbnail!.source, startsWith('https://'));
    });

    test('fromJson parses content_urls', () {
      final json = {
        ...minimalJson,
        'content_urls': {
          'desktop': {'page': 'https://en.wikipedia.org/wiki/Earth'},
          'mobile': {'page': 'https://en.m.wikipedia.org/wiki/Earth'},
        },
      };
      final summary = PageSummary.fromJson(json);
      expect(summary.contentUrls, isNotNull);
      expect(summary.contentUrls!.desktopUrl, contains('en.wikipedia.org'));
      expect(summary.contentUrls!.mobileUrl, contains('en.m.wikipedia.org'));
    });

    test('fromJson parses wikibase_item', () {
      final json = {...minimalJson, 'wikibase_item': 'Q2'};
      final summary = PageSummary.fromJson(json);
      expect(summary.wikidataId, 'Q2');
    });

    test('fromJson parses timestamp', () {
      final json = {
        ...minimalJson,
        'timestamp': '2024-01-15T12:00:00Z',
      };
      final summary = PageSummary.fromJson(json);
      expect(summary.lastModified, isNotNull);
      expect(summary.lastModified!.year, 2024);
    });

    test('copyWith creates modified copy', () {
      final summary = PageSummary.fromJson(minimalJson);
      final copy = summary.copyWith(title: 'Moon');
      expect(copy.title, 'Moon');
      expect(copy.pageId, summary.pageId);
    });

    test('equality holds for identical instances', () {
      final a = PageSummary.fromJson(minimalJson);
      final b = PageSummary.fromJson(minimalJson);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality when fields differ', () {
      final a = PageSummary.fromJson(minimalJson);
      final b = a.copyWith(title: 'Moon');
      expect(a, isNot(equals(b)));
    });
  });

  group('WikiThumbnail', () {
    test('fromJson round-trips correctly', () {
      const json = <String, dynamic>{
        'source': 'https://example.com/thumb.jpg',
        'width': 640,
        'height': 480,
      };
      final thumb = WikiThumbnail.fromJson(json);
      expect(thumb.source, 'https://example.com/thumb.jpg');
      expect(thumb.width, 640);
      expect(thumb.height, 480);
    });

    test('equality and hashCode', () {
      const a = WikiThumbnail(
        source: 'https://example.com/a.jpg',
        width: 320,
        height: 240,
      );
      const b = WikiThumbnail(
        source: 'https://example.com/a.jpg',
        width: 320,
        height: 240,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ContentUrls', () {
    test('fromJson maps desktop and mobile page URLs', () {
      final json = <String, dynamic>{
        'desktop': {'page': 'https://en.wikipedia.org/wiki/Earth'},
        'mobile': {'page': 'https://en.m.wikipedia.org/wiki/Earth'},
      };
      final urls = ContentUrls.fromJson(json);
      expect(urls.desktopUrl, 'https://en.wikipedia.org/wiki/Earth');
      expect(urls.mobileUrl, 'https://en.m.wikipedia.org/wiki/Earth');
    });
  });
}
