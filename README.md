# Wikimedia Dart

A production-ready, type-safe Dart SDK for the Wikimedia REST APIs.

## Overview

Wikimedia Dart provides a structured, type-safe client library to interact with the Wikimedia REST APIs. It is designed to work across multiple platforms (mobile, desktop, and web) with zero reliance on Flutter dependencies.

This SDK is not an official Wikimedia Foundation library. It is maintained independently.

## Motivation

Integrating Wikipedia, Wiktionary, or Commons data into Dart or Flutter applications has historically relied on direct HTTP calls or web scraping. This SDK provides complete static typing, built-in exception mapping, predictable client resource lifecycle management, and transparent multi-project support.

## Features

- Fully typed endpoints for page summaries, raw HTML, related pages, search, autocomplete, and media access.
- Built-in mapped exception hierarchy for predictable error handling (e.g. 404, 429, 500 mapping).
- Multi-project support, including Wikipedia, Wiktionary, Commons, and custom MediaWiki instances.
- Zero Flutter dependency; runs on standard Dart VMs, server-side, or CLI apps.
- Comprehensive request timeouts, custom base-URL injection, and user-agent settings.

## Installation

Add `wikimedia_dart` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  wikimedia_dart: ^0.1.0-beta.1
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
`WikimediaDart/0.1.0-beta.1 (https://github.com/Zaidusyy/wikimedia_dart)`

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

// Get related articles
final relatedResponse = await wiki.pages.related('Earth');
for (final page in relatedResponse) {
  print('Related page: ${page.title}');
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

## Error Handling

Wikimedia Dart translates raw HTTP response statuses into a structured exception hierarchy:

- `WikiNotFoundException` — Status code 404 (resource does not exist).
- `WikiRateLimitException` — Status code 429 (rate limits exceeded; includes `retryAfter` duration if provided by the API).
- `WikiServerException` — Status code 5xx (Wikimedia server errors).
- `WikiNetworkException` — Underlying socket connection, DNS, or network transport issues.
- `WikiParseException` — Structural formatting issues with response JSON deserialization.

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

Initialize constructors are available for:

- `WikiClient.wikipedia()` — Wikipedia instances (supports BCP 47 language prefixing).
- `WikiClient.wiktionary()` — Wiktionary instances (supports BCP 47 language prefixing).
- `WikiClient.commons()` — Wikimedia Commons (does not use language prefixes).
- `WikiClient.custom(baseUrl: 'https://wiki.example.org')` — Custom MediaWiki REST API integrations.

## Known Limitations

- **Wiktionary Summary Endpoint**: Wikimedia's REST API does not support the `/page/summary/{title}` endpoint for Wiktionary projects. Consequently, calling `wiki.pages.summary()` on a Wiktionary-configured client will throw a `WikiNotFoundException` (HTTP 404). This is an upstream API limitation. Callers targeting Wiktionary should use the `pages.html()` or `search` endpoints instead, which are fully supported.

## Quality Guarantees

- **Test Suite**: 100% test coverage across all namespaces.
- **Contract Mocks**: Isolated unit testing against captured Wikimedia REST API shapes.
- **Static Analysis**: Enforced strict-casts, strict-inference, and zero warnings.

## Architecture Principles

- **Separation of Concerns**: Endpoint routing logic is encapsulated in `UrlBuilder`. JSON deserialization logic resides in model classes. Service layers manage raw networking via `ServiceBase`.
- **Client Ownership**: The client handles connection pooling via its underlying `http.Client`. Callers are responsible for calling `close()` when the client is no longer needed.
- **No Side Effects**: Methods are read-only and execute no mutations on user accounts or Wikimedia states.

## Contributing

Contributions are welcome. Please ensure that:
1. All changes compile cleanly under `dart analyze --fatal-infos`.
2. New features or fixes are covered by unit and integration tests.
3. Code is formatted using `dart format .`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Author

Developed and maintained by [Zaidusyy (Zaid Sayyed)](https://github.com/Zaidusyy).

