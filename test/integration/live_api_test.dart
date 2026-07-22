@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

/// Live integration tests that exercise the real Wikimedia REST API.
///
/// These are **skipped by default** (see `dart_test.yaml`). They exist to
/// catch upstream contract drift that fixture-based unit tests cannot. Run
/// them explicitly:
///
/// ```
/// dart test --run-skipped --tags integration
/// ```
///
/// Assertions deliberately check structure and invariants rather than exact
/// content, since article text changes over time.
void main() {
  const userAgent =
      'wikimedia_dart integration tests (https://github.com/Zaidusyy/wikimedia_dart)';
  const timeout = Timeout(Duration(seconds: 30));

  late WikiClient wiki;
  late WikiClient commons;

  setUpAll(() {
    wiki = WikiClient.wikipedia(userAgent: userAgent);
    commons = WikiClient.commons(userAgent: userAgent);
  });

  tearDownAll(() {
    wiki.close();
    commons.close();
  });

  group('live Wikimedia API', () {
    test('pages.summary returns a populated summary', () async {
      final summary = await wiki.pages.summary('Earth');
      expect(summary.title, isNotEmpty);
      expect(summary.extract, isNotEmpty);
      expect(summary.pageId, greaterThan(0));
      expect(summary.contentUrls?.desktopUrl, contains('wikipedia.org'));
    }, timeout: timeout);

    test('pages.html returns HTML content', () async {
      final html = await wiki.pages.html('Earth');
      expect(html, isNotEmpty);
      expect(html, contains('<'));
    }, timeout: timeout);

    test('pages.related returns related pages via morelike', () async {
      final related = await wiki.pages.related('Earth', limit: 5);
      expect(related, isA<List<SearchResultItem>>());
      expect(related, isNotEmpty);
      expect(related.first.title, isNotEmpty);
    }, timeout: timeout);

    test('search.pages returns matching pages', () async {
      final response = await wiki.search.pages('climate change', limit: 3);
      expect(response.pages, isNotEmpty);
      expect(response.pages.length, lessThanOrEqualTo(3));
      expect(response.pages.first.title, isNotEmpty);
    }, timeout: timeout);

    test('search.autocomplete returns suggestions', () async {
      final suggestions = await wiki.search.autocomplete('Ear', limit: 5);
      expect(suggestions, isNotEmpty);
      expect(suggestions.length, lessThanOrEqualTo(5));
    }, timeout: timeout);

    test('media.listForPage returns media items', () async {
      final items = await wiki.media.listForPage('Earth');
      expect(items, isNotEmpty);
      expect(items.first.title, isNotEmpty);
    }, timeout: timeout);

    test('media.getFile returns file metadata from Commons', () async {
      final file =
          await commons.media.getFile('File:Earth Western Hemisphere.jpg');
      expect(file.title, isNotEmpty);
    }, timeout: timeout);

    test('language override targets the localized wiki', () async {
      final summary = await wiki.pages.summary('Terre', language: 'fr');
      expect(summary.language, 'fr');
      expect(summary.contentUrls?.desktopUrl, contains('fr.wikipedia.org'));
    }, timeout: timeout);

    test('a missing page throws WikiNotFoundException', () async {
      await expectLater(
        () => wiki.pages.summary('ThisArticleDefinitelyDoesNotExist_zzq123'),
        throwsA(isA<WikiNotFoundException>()),
      );
    }, timeout: timeout);
  });
}
