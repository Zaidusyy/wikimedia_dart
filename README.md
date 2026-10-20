# Wikimedia Dart

[![pub package](https://img.shields.io/pub/v/wikimedia_dart.svg)](https://pub.dev/packages/wikimedia_dart)
[![CI](https://github.com/Zaidusyy/wikimedia_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/Zaidusyy/wikimedia_dart/actions/workflows/ci.yml)
[![pub points](https://img.shields.io/pub/points/wikimedia_dart)](https://pub.dev/packages/wikimedia_dart/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A typed Dart client for the Wikimedia REST APIs: Wikipedia, Wiktionary, and
Commons. It runs anywhere Dart does (Flutter, server, CLI, web) and doesn't
depend on Flutter.

It's an independent project, not an official Wikimedia Foundation library.

## Features

- Page summaries, article HTML, related pages, full-text search,
  autocomplete, and media.
- Typed models, and one sealed exception type for every failure.
- Retries with backoff for rate limits, server errors, and network failures.
- A language override on each call, so one client can read any language
  edition.
- Configurable timeout and User-Agent.

## Installation

```yaml
dependencies:
  wikimedia_dart: ^0.1.2
```

## Quick start

```dart
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() async {
  final wiki = WikiClient.wikipedia(
    userAgent: 'MyApp/1.0 (you@example.com)',
  );

  try {
    final summary = await wiki.pages.summary('Earth');
    print(summary.title);
    print(summary.extract);
  } finally {
    wiki.close();
  }
}
```

A client holds one HTTP connection pool, so reuse it and call `close()` when
you're done.

## Identify your app

Wikimedia asks every client to send a User-Agent that names the app and gives
a way to contact you (see the
[User-Agent policy](https://foundation.wikimedia.org/wiki/Policy:Wikimedia_Foundation_User-Agent_Policy)).
Requests without one get much lower rate limits, and some are refused.

```dart
final wiki = WikiClient.wikipedia(
  userAgent: 'MyApp/1.2.0 (you@example.com; https://myapp.example)',
);
```

If you don't pass one, the package sends
`WikimediaDart/<version> (https://github.com/Zaidusyy/wikimedia_dart)`.
That's fine for trying things out, but it's shared by everyone using the
package, so set your own in anything you ship.

## Examples

### Pages

```dart
final wiki = WikiClient.wikipedia();

// The article's HTML.
final html = await wiki.pages.html('Earth');

// Pages similar to this one (a "more like this" search).
final related = await wiki.pages.related('Earth', limit: 5);
for (final page in related) {
  print('${page.title}: ${page.description}');
}
```

### Search

```dart
final results = await wiki.search.pages('climate change', limit: 5);
for (final page in results.pages) {
  print('${page.title}: ${page.description}');
}

// Titles for a type-ahead box.
final titles = await wiki.search.autocomplete('Eart');
```

`limit` is 1 to 100 on every search call.

### Media

```dart
// Media used in an article.
final media = await wiki.media.listForPage('Earth');
for (final item in media) {
  print(item.title);
}

// Details of one file. Files used on Wikipedia mostly live on Commons,
// so ask a Commons client.
final commons = WikiClient.commons();
final file = await commons.media.getFile('File:Earth_Western_Hemisphere.jpg');
print(file.sourceUrl);
```

## Other languages

Wikipedia and Wiktionary clients default to English. Pass `language` to a
constructor, or to a single call, with the wiki's subdomain code (`fr`, `de`,
`simple`, `zh-yue`, ...):

```dart
final wiki = WikiClient.wikipedia();

final french = await wiki.pages.summary('Terre', language: 'fr');
final german = await wiki.pages.summary('Erde', language: 'de');
```

Commons and custom clients have no language subdomain and ignore it.

## Retries

Requests are all `GET`s, so failures that are likely to pass are retried:
429, 5xx, network errors, and timeouts. A 404, any other 4xx, and a response
that can't be parsed are thrown straight away. When the server sends
`Retry-After` (on a 429 or 503), the client waits that long, up to
`maxBackoff`.

The default is 3 retries, waiting 500ms, 1s, then 2s. Change it with
`RetryPolicy`:

```dart
final wiki = WikiClient.wikipedia(
  retryPolicy: const RetryPolicy(
    maxRetries: 5,
    initialBackoff: Duration(milliseconds: 200),
    maxBackoff: Duration(seconds: 20),
  ),
);

// No retries.
final once = WikiClient.wikipedia(retryPolicy: const RetryPolicy.none());
```

When the retries run out, the last failure is thrown.

## Errors

Every failure is a `WikiException`:

- `WikiNotFoundException`: 404, the page or file doesn't exist.
- `WikiRateLimitException`: 429. Has `retryAfter` when the API sends it.
- `WikiRequestException`: any other 4xx (400, 401, 403, ...).
- `WikiServerException`: 5xx, or a status the package doesn't expect. Has
  `retryAfter` when the server sends it.
- `WikiNetworkException`: DNS, socket, or connection failure.
- `WikiTimeoutException`: no response within the timeout.
- `WikiParseException`: the response wasn't in the expected shape.

When the server explains an error, its reason is included in the message.

```dart
try {
  await wiki.pages.summary('ThisPageDoesNotExist');
} on WikiNotFoundException {
  print('No such article');
} on WikiRateLimitException catch (e) {
  print('Rate limited, retry after ${e.retryAfter}');
} on WikiException catch (e) {
  print(e.message);
}
```

## Projects

- `WikiClient.wikipedia()`: Wikipedia.
- `WikiClient.wiktionary()`: Wiktionary.
- `WikiClient.commons()`: Wikimedia Commons.
- `WikiClient.custom(baseUrl: ...)`: a self-hosted MediaWiki, search only for
  now (see below).

## Known limitations

- Wiktionary has no summary endpoint, so `pages.summary()` on a Wiktionary
  client throws `WikiNotFoundException`. Use `pages.html()` or search there.
- Wikidata has no summary or media-list endpoint either; only `pages.html()`
  and search work.
- `WikiClient.custom()` only uses the host of `baseUrl` and always connects
  over HTTPS on the default port. Search works on a wiki that serves its
  scripts from `/w`; summaries, HTML and media don't. Full support for
  self-hosted wikis is planned for 0.2.0.
- Browsers don't let web apps set `User-Agent`, so on Flutter web your
  `userAgent` may not reach Wikimedia.

## Contributing

Before opening a PR, run:

```bash
dart format .
dart analyze --fatal-infos
dart test
```

New behavior needs unit tests. The live API tests are skipped by default;
run them with `dart test --run-skipped --tags integration`.

## License

MIT. See [LICENSE](LICENSE).

Maintained by [Zaid Sayyed](https://github.com/Zaidusyy).
