// ignore_for_file: avoid_print

import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() async {
  // Name your app and give a contact; Wikimedia rate-limits anonymous
  // clients much harder.
  final wiki = WikiClient.wikipedia(
    userAgent:
        'wikimedia_dart-example (https://github.com/Zaidusyy/wikimedia_dart)',
  );

  try {
    final summary = await wiki.pages.summary('Earth');
    print('${summary.title}: ${summary.description}');
    print(summary.extract);
    print(summary.contentUrls?.desktopUrl);

    print('\nSearch:');
    final results = await wiki.search.pages('climate change', limit: 3);
    for (final page in results.pages) {
      print('  ${page.title}: ${page.description ?? '-'}');
    }

    print('\nRelated to Earth:');
    for (final page in await wiki.pages.related('Earth', limit: 3)) {
      print('  ${page.title}');
    }

    final media = await wiki.media.listForPage('Earth');
    print('\nEarth has ${media.length} media items.');
    if (media.isNotEmpty) print('First one: ${media.first.title}');

    final french = await wiki.pages.summary('Terre', language: 'fr');
    print('\nIn French: ${french.title}');

    try {
      await wiki.pages.summary('ThisPageDefinitelyDoesNotExist12345');
    } on WikiNotFoundException catch (e) {
      print('\nMissing pages throw WikiNotFoundException: ${e.uri}');
    }
  } on WikiException catch (e) {
    print('Request failed: $e');
  } finally {
    wiki.close();
  }
}
