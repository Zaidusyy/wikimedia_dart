// ignore_for_file: avoid_print

import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() async {
  final wiki = WikiClient.wikipedia();

  try {
    print('--- Fetching Page Summary ---');
    final summary = await wiki.pages.summary('Earth');
    print('Title: ${summary.title}');
    print('Description: ${summary.description}');
    print('Extract: ${summary.extract}');
    print('Desktop URL: ${summary.contentUrls?.desktopUrl ?? "N/A"}');
    print('');

    print('--- Full-Text Search ---');
    final searchResponse = await wiki.search.pages('Climate change', limit: 3);
    for (final page in searchResponse.pages) {
      print(
          '- ${page.title}: ${page.description ?? "No description available"}');
    }
    print('');

    print('--- Related Pages ---');
    final related = await wiki.pages.related('Earth', limit: 3);
    for (final page in related) {
      print('- ${page.title}');
    }
    print('');

    print('--- Media On A Page ---');
    final media = await wiki.media.listForPage('Earth');
    print('${media.length} media items; first: ${media.first.title}');
    print('');

    print('--- Language Override ---');
    final frenchSummary = await wiki.pages.summary('Terre', language: 'fr');
    print('Title (FR): ${frenchSummary.title}');
    print('Extract (FR): ${frenchSummary.extract}');
    print('');

    print('--- Error Handling ---');
    try {
      await wiki.pages.summary('ThisPageDefinitelyDoesNotExist12345');
    } on WikiNotFoundException catch (e) {
      print('Expected Exception: Page not found.');
      print('Exception message: ${e.message}');
      print('Target URI: ${e.uri}');
    }
  } on WikiException catch (e) {
    print('An unexpected Wikimedia API error occurred: ${e.message}');
  } finally {
    wiki.close();
    print('');
    print('Client closed successfully.');
  }
}
