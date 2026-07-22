# Wikimedia Dart

A type-safe Dart client for the Wikimedia REST APIs.

## Overview

Wikimedia Dart is a typed client for the Wikimedia REST APIs. It runs anywhere Dart does (mobile, desktop, web, server, CLI) and doesn't depend on Flutter.

It's an independent project, not an official Wikimedia Foundation library.

## Why

Pulling Wikipedia, Wiktionary, or Commons data into a Dart app usually means hand-rolling HTTP calls or scraping. This package gives you typed responses, a single exception hierarchy for errors, clear client lifecycle, and one client that can target several projects.

## Features

- Typed endpoints for page summaries, raw HTML, related pages, search, autocomplete, and media.
- One exception hierarchy that maps HTTP status codes (404, 429, 4xx, 5xx) to typed errors.
- Automatic retry with backoff for transient failures.
- Works with Wikipedia, Wiktionary, Commons, and self-hosted MediaWiki.
- No Flutter dependency; runs on the plain Dart VM, servers, and CLIs.
- Configurable timeouts, base URL, and User-Agent.

## Installation

Add `wikimedia_dart` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  wikimedia_dart: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() async {
  // Initialize a client targeting Wikipedia
  final wiki = WikiClient.wikipedia();

  try {
    // Fetch summary for the "Earth" article
    final summary = await wiki.pages.summary('Earth');
    print('Title: ${summary.title}');
    print('Extract: ${summary.extract}');
  } finally {
    // Always close the client to release resources
    wiki.close();
  }
}
```

## User-Agent Policy and Best Practices

To comply with the [Wikimedia User-Agent Policy](https://meta.wikimedia.org/wiki/User-Agent_policy), all applications accessing Wikimedia APIs must supply a clear, descriptive, and unique `User-Agent` header. This allows Wikimedia sysadmins to identify your application and contact you in case of excessive resource consumption, avoiding automated IP-based rate limiting or blocks.

By default, `WikiClient` generates a generic User-Agent:
`WikimediaDart/0.1.0 (https://github.com/Zaidusyy/wikimedia_dart)`

### Customizing the User-Agent (Recommended)

When initializing the `WikiClient` in production applications, you should always supply a custom User-Agent identifying your application name, version, and contact information (such as an email or website):

```dart
final wiki = WikiClient.wikipedia(
  userAgent: 'MyCoolApp/1.2.0 (contact@example.com; https://mycoolapp.com)',
);
```

**Wikimedia expectations for your User-Agent string:**
1. **Be unique and descriptive**: Include your application name and version.
2. **Provide contact info**: Provide a valid contact email address or application website URL.
3. **Do not spoof**: Never fake your browser User-Agent or use generic headers, as this can trigger aggressive security filters.

## Examples

### Page Summaries, HTML, and Related Articles

```dart
final wiki = WikiClient.wikipedia();

// Get the raw HTML content of an article
final htmlContent = await wiki.pages.html('Earth');

// Get related articles ("more like this" search).
// Returns List<SearchResultItem>.
final relatedPages = await wiki.pages.related('Earth', limit: 5);
for (final page in relatedPages) {
  print('Related page: ${page.title} (${page.description})');
}
```

### Full-Text Search and Autocomplete

```dart
final wiki = WikiClient.wikipedia();

// Perform full-text search
final searchResult = await wiki.search.pages('Climate change', limit: 5);
for (final page in searchResult.pages) {
  print('${page.title}: ${page.description}');
}

// Perform title autocomplete
final suggestions = await wiki.search.autocomplete('Eart');
for (final suggestion in suggestions) {
  print('Suggestion: $suggestion');
}
```

### Media and File Metadata

```dart
final wiki = WikiClient.wikipedia();

// List all media files used on a page
final mediaList = await wiki.media.listForPage('Earth');
for (final mediaItem in mediaList) {
  print('Media Title: ${mediaItem.title}');
}

// Retrieve file information from Wikimedia Commons
final commons = WikiClient.commons();
final fileMetadata = await commons.media.getFile('File:Earth.jpg');
print('Source URL: ${fileMetadata.sourceUrl}');
```

## Language Override

Every API method supports a BCP 47 language override to query localized wikis. By default, Wikipedia and Wiktionary clients target English (`en`).

```dart
final wiki = WikiClient.wikipedia();

// Query in French
final frenchSummary = await wiki.pages.summary('Terre', language: 'fr');

// Query in German
final germanSummary = await wiki.pages.summary('Erde', language: 'de');
```

## Retries and Resilience

Wikimedia Dart automatically retries transient failures with exponential
backoff. Because every request is an idempotent `GET`, retrying is safe. The
following failures are retried:

- `WikiRateLimitException` (HTTP 429)
- `WikiServerException` with a 5xx status code (502/503/504, etc.)
- `WikiNetworkException` (socket / DNS / connection failures)
- `WikiTimeoutException` (request exceeded the configured timeout)

Non-transient failures are never retried: 404, parse errors, and 4xx responses
other than 429. When the server sends a `Retry-After` header (on a 429 or 503),
that value is used, capped at `maxBackoff`.

Retries are **enabled by default** (3 retries; 500ms, 1s, 2s backoff). Tune
or disable them via `RetryPolicy`:

```dart
// Custom policy: 5 retries, faster initial backoff.
final wiki = WikiClient.wikipedia(
  retryPolicy: const RetryPolicy(
    maxRetries: 5,
    initialBackoff: Duration(milliseconds: 200),
    maxBackoff: Duration(seconds: 20),
  ),
);

// Disable retries entirely.
final noRetry = WikiClient.wikipedia(
  retryPolicy: const RetryPolicy.none(),
);
```

If every retry is exhausted, the final failure is thrown as the corresponding
`WikiException`, so existing error handling continues to work unchanged.

## Error Handling

Every HTTP status maps to a typed exception:

- `WikiNotFoundException`: 404, the resource doesn't exist.
- `WikiRateLimitException`: 429, rate limit hit. Carries `retryAfter` when the API sends it.
- `WikiRequestException`: a 4xx other than 404/429 (400, 401, 403, ...); the request itself was rejected.
- `WikiServerException`: 5xx server error. Carries `retryAfter` when the server sends it.
- `WikiNetworkException`: socket, DNS, or connection failure.
- `WikiTimeoutException`: the request ran past the configured timeout.
- `WikiParseException`: the response didn't match the expected shape.

```dart
try {
  final summary = await wiki.pages.summary('ThisPageDoesNotExist');
} on WikiNotFoundException catch (e) {
  print('Article not found: ${e.message}');
} on WikiRateLimitException catch (e) {
  print('Rate limited. Retry after: ${e.retryAfter}');
} on WikiException catch (e) {
  print('General SDK exception: ${e.message}');
}
```

## Supported Wikimedia Projects

Named constructors cover the common cases:

- `WikiClient.wikipedia()`: Wikipedia, with a BCP 47 language.
- `WikiClient.wiktionary()`: Wiktionary, with a BCP 47 language.
- `WikiClient.commons()`: Wikimedia Commons (no language prefix).
- `WikiClient.custom(baseUrl: 'https://wiki.example.org')`: any self-hosted MediaWiki.

## Known Limitations

Wikimedia's REST API doesn't expose `/page/summary/{title}` for Wiktionary, so `wiki.pages.summary()` on a Wiktionary client returns a 404 (`WikiNotFoundException`). It's an upstream gap; use `pages.html()` or `search` for Wiktionary instead.

## Design notes

Requests are read-only, so nothing here changes accounts or wiki content. URL construction lives in `UrlBuilder`, JSON parsing lives in the model classes, and the networking (headers, timeout, retries, error mapping) lives in `ServiceBase`. A client owns one `http.Client` and its connection pool, so call `close()` when you're done with it.

## Contributing

Contributions are welcome. Before opening a PR, please check that:

1. `dart analyze --fatal-infos` is clean.
2. New behavior has unit tests (and integration tests where it makes sense).
3. `dart format .` has been run.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Author

Developed and maintained by [Zaidusyy (Zaid Sayyed)](https://github.com/Zaidusyy).

