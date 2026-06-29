import 'package:test/test.dart';
import 'package:wikimedia_dart/src/client/wiki_config.dart';
import 'package:wikimedia_dart/src/utils/url_builder.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() {
  group('UrlBuilder', () {
    late WikiConfig englishWikipedia;
    late WikiConfig frenchWikipedia;
    late WikiConfig commons;
    late WikiConfig wikidata;

    setUp(() {
      englishWikipedia = const WikiConfig(
        language: 'en',
        project: WikiProject.wikipedia,
        timeout: Duration(seconds: 30),
        userAgent: 'test/1.0',
      );
      frenchWikipedia = const WikiConfig(
        language: 'fr',
        project: WikiProject.wikipedia,
        timeout: Duration(seconds: 30),
        userAgent: 'test/1.0',
      );
      commons = const WikiConfig(
        language: 'en',
        project: WikiProject.commons,
        timeout: Duration(seconds: 30),
        userAgent: 'test/1.0',
      );
      wikidata = const WikiConfig(
        language: 'en',
        project: WikiProject.wikidata,
        timeout: Duration(seconds: 30),
        userAgent: 'test/1.0',
      );
    });

    test('Wikipedia English produces correct URI', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/Earth',
      );
      expect(
        uri.toString(),
        'https://en.wikipedia.org/api/rest_v1/page/summary/Earth',
      );
    });

    test('Wikipedia French produces correct host', () {
      final uri = UrlBuilder.build(
        config: frenchWikipedia,
        path: '/page/summary/Terre',
      );
      expect(uri.host, 'fr.wikipedia.org');
    });

    test('Commons has no language prefix', () {
      final uri = UrlBuilder.build(
        config: commons,
        path: '/page/summary/File:Earth.jpg',
      );
      expect(uri.host, 'commons.wikimedia.org');
      expect(uri.host, isNot(contains('en.')));
    });

    test('Wikidata has no language prefix', () {
      final uri = UrlBuilder.build(
        config: wikidata,
        path: '/page/summary/Q2',
      );
      expect(uri.host, 'www.wikidata.org');
      expect(uri.host, isNot(contains('en.')));
    });

    test('Language override applies for per-request override', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/Terre',
        languageOverride: 'fr',
      );
      expect(uri.host, 'fr.wikipedia.org');
    });

    test('Language override does not apply when null', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/Earth',
        // languageOverride omitted → defaults to null → uses config.language
      );
      expect(uri.host, 'en.wikipedia.org');
    });

    test('Titles with spaces are percent-encoded', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/${Uri.encodeComponent('New York City')}',
      );
      expect(uri.path, contains('New%20York%20City'));
    });

    test('Non-ASCII titles are percent-encoded', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/${Uri.encodeComponent('北京')}',
      );
      // Exact encoding — Uri() must not double-encode the % from encodeComponent.
      expect(uri.path, contains('%E5%8C%97%E4%BA%AC'));
      expect(uri.path, isNot(contains('北京')));
    });

    // ---------------------------------------------------------------------------
    // Regression tests: Uri() must not double-encode pre-encoded characters.
    // These cover every character class that Uri.https() was known to corrupt.
    // ---------------------------------------------------------------------------

    test('Titles with slashes are percent-encoded and not double-encoded', () {
      // 'AC/DC' → 'AC%2FDC'  (the slash must become %2F, not %252F)
      final encoded = Uri.encodeComponent('AC/DC');
      expect(encoded, 'AC%2FDC');
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/$encoded',
      );
      expect(uri.path, contains('AC%2FDC'));
      expect(uri.path, isNot(contains('AC%252FDC')));
    });

    test(
        'Titles with question marks are percent-encoded and not double-encoded',
        () {
      // 'C#?' — the ? must become %3F, not be interpreted as query string start
      final encoded = Uri.encodeComponent('C#?');
      expect(encoded, 'C%23%3F');
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/$encoded',
      );
      expect(uri.path, contains('C%23%3F'));
      expect(uri.path, isNot(contains('C%2523%253F')));
      // The question mark must NOT leak into the query string.
      expect(uri.queryParameters, isEmpty);
    });

    test(
        'Titles containing literal % are percent-encoded and not double-encoded',
        () {
      // '100% true' → '100%25%20true'  (% becomes %25, space becomes %20)
      final encoded = Uri.encodeComponent('100% true');
      expect(encoded, '100%25%20true');
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/$encoded',
      );
      expect(uri.path, contains('100%25%20true'));
      // If Uri() double-encoded, % would become %25 again: '100%2525%2520true'
      expect(uri.path, isNot(contains('100%2525')));
    });

    test('Query parameters are included in URI', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/search',
        queryParameters: {'q': 'climate change', 'limit': '10'},
      );
      expect(uri.queryParameters['q'], 'climate change');
      expect(uri.queryParameters['limit'], '10');
    });

    test('Custom base URL uses the provided host', () {
      const custom = WikiConfig(
        language: 'en',
        project: WikiProject.wikipedia,
        timeout: Duration(seconds: 30),
        userAgent: 'test/1.0',
        customBaseUrl: 'https://wiki.example.org',
      );
      final uri = UrlBuilder.build(
        config: custom,
        path: '/page/summary/Test',
      );
      expect(uri.host, 'wiki.example.org');
    });

    test('Path starts with /api/rest_v1 for non-search paths', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/page/summary/Earth',
      );
      expect(uri.path, startsWith('/api/rest_v1/page/summary'));
    });

    test('Path starts with /w/rest.php/v1 for search paths', () {
      final uri = UrlBuilder.build(
        config: englishWikipedia,
        path: '/search/page',
      );
      expect(uri.path, startsWith('/w/rest.php/v1/search/page'));
    });

    // WikiProject.supportsLanguagePrefix coverage
    test('Wikipedia supports language prefix', () {
      expect(WikiProject.wikipedia.supportsLanguagePrefix, isTrue);
    });

    test('Commons does not support language prefix', () {
      expect(WikiProject.commons.supportsLanguagePrefix, isFalse);
    });

    test('Wikidata does not support language prefix', () {
      expect(WikiProject.wikidata.supportsLanguagePrefix, isFalse);
    });

    test('Wiktionary supports language prefix', () {
      expect(WikiProject.wiktionary.supportsLanguagePrefix, isTrue);
      final uri = UrlBuilder.build(
        config: const WikiConfig(
          language: 'es',
          project: WikiProject.wiktionary,
          timeout: Duration(seconds: 30),
          userAgent: 'test/1.0',
        ),
        path: '/page/summary/casa',
      );
      expect(uri.host, 'es.wiktionary.org');
    });
  });
}
