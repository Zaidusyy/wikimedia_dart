import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

import '../test_helpers.dart';

/// Every model's `toJson` has to round-trip through its `fromJson`, or the
/// cache landing in 0.3.0 will quietly hand back different objects than the
/// ones it stored.
void main() {
  group('PageSummary', () {
    test('round-trips a real API response', () {
      final original =
          PageSummary.fromJson(fixtureMap('responses/page_summary_earth.json'));

      expect(PageSummary.fromJson(original.toJson()), original);
    });

    test('round-trips with every optional field absent', () {
      const minimal = PageSummary(
        title: 'Earth',
        displayTitle: 'Earth',
        pageId: 9228,
        language: 'en',
      );

      expect(PageSummary.fromJson(minimal.toJson()), minimal);
    });

    test('omits absent fields rather than writing nulls', () {
      const minimal = PageSummary(
        title: 'Earth',
        displayTitle: 'Earth',
        pageId: 9228,
        language: 'en',
      );

      expect(minimal.toJson().keys,
          unorderedEquals(['title', 'displaytitle', 'pageid', 'lang']));
    });
  });

  group('SearchResponse', () {
    test('round-trips a real API response', () {
      final original = SearchResponse.fromJson(
        fixtureMap('responses/search_climate_change.json'),
      );

      expect(SearchResponse.fromJson(original.toJson()), original);
    });

    test('compares equal by page contents, not list identity', () {
      const item = SearchResultItem(title: 'Earth', pageId: 9228);

      expect(
        const SearchResponse(pages: [item]),
        const SearchResponse(pages: [item]),
      );
      expect(
        const SearchResponse(pages: [item]).hashCode,
        const SearchResponse(pages: [item]).hashCode,
      );
    });

    test('still compares unequal when the pages differ', () {
      expect(
        const SearchResponse(
          pages: [SearchResultItem(title: 'Earth', pageId: 9228)],
        ),
        isNot(const SearchResponse(
          pages: [SearchResultItem(title: 'Mars', pageId: 14640)],
        )),
      );
    });
  });

  group('MediaFile', () {
    test('round-trips a full file', () {
      const original = MediaFile(
        title: 'File:Earth_Western_Hemisphere.jpg',
        sourceUrl: 'https://upload.wikimedia.org/earth.jpg',
        description: 'The Earth',
        mimeType: 'image/jpeg',
        width: 1200,
        height: 1200,
        fileSizeBytes: 45678,
      );

      expect(MediaFile.fromJson(original.toJson()), original);
    });

    test('round-trips with only the required fields', () {
      const minimal = MediaFile(
        title: 'File:Earth.jpg',
        sourceUrl: 'https://upload.wikimedia.org/earth.jpg',
      );

      expect(MediaFile.fromJson(minimal.toJson()), minimal);
    });
  });

  group('MediaItem', () {
    test('round-trips a full item', () {
      const original = MediaItem(
        title: 'File:Earth.jpg',
        type: 'image',
        srcUrl: 'https://upload.wikimedia.org/earth.jpg',
        caption: 'The Earth from space',
      );

      expect(MediaItem.fromJson(original.toJson()), original);
    });

    test('round-trips without a source URL', () {
      const minimal = MediaItem(title: 'File:Earth.jpg', type: 'image');

      expect(MediaItem.fromJson(minimal.toJson()), minimal);
    });
  });

  group('WikiThumbnail and ContentUrls', () {
    test('thumbnail round-trips', () {
      const original = WikiThumbnail(
        source: 'https://upload.wikimedia.org/earth-thumb.jpg',
        width: 320,
        height: 240,
      );

      expect(WikiThumbnail.fromJson(original.toJson()), original);
    });

    test('content URLs round-trip through the nested shape', () {
      const original = ContentUrls(
        desktopUrl: 'https://en.wikipedia.org/wiki/Earth',
        mobileUrl: 'https://en.m.wikipedia.org/wiki/Earth',
      );

      expect(ContentUrls.fromJson(original.toJson()), original);
    });
  });
}
