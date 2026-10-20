# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2026-10-21

### Fixed

- `search.pages()`, `search.autocomplete()` and `pages.related()` returned
  garbled text for anything outside ASCII when the app resolved http older
  than 1.4.0, which the `^1.2.0` constraint allows. Those endpoints send JSON
  without a charset, and older http decoded it as latin1. JSON responses are
  now always decoded as UTF-8.
- `close()` didn't stop a call already in progress: it kept retrying, so
  requests were still sent after `close()`. It now stops and rethrows the last
  failure.
- One search hit whose thumbnail had no width or height made the whole
  `search.pages()` or `related()` call throw `WikiParseException`. Missing
  dimensions now read as 0.
- Titles with spaces were sent as `%20`. The HTML endpoint answers that with a
  redirect, which cost a second request. Titles now go out with underscores,
  the form MediaWiki uses itself.
- `toString()` on exceptions printed minified type names in release web
  builds. The names are now spelled out.
- A fractional timeout was reported in whole seconds, so 1500ms read as "1s".
- The default `User-Agent` reported a hardcoded `WikimediaDart/0.1.0` from
  every constructor, so 0.1.1 identified itself to Wikimedia as 0.1.0. It is
  now derived from a single version constant, and a test asserts that constant
  matches `pubspec.yaml` so a release bump can't leave it behind again.
- `SearchResponse` compared its `pages` list by identity, so two responses
  holding equal results were never equal. They now compare element by element,
  with a matching `hashCode`.
- The SDK constraint said Dart 3.0, but `http ^1.2.0` already needed 3.2. It
  now says 3.2.

### Added

- `toJson()` on every model, round-tripping through the matching `fromJson()`.
  Absent optional fields are omitted rather than written as `null`.

### Changed

- Exception messages include the server's reason when an error response
  carries one, for example why a 400 was rejected.
- The README and API docs now say what actually works: `custom()` only
  supports search in 0.1.x, the language override is the wiki's subdomain
  code, `getFile()` needs a Commons client for Commons files, and Wikidata has
  no summary or media-list endpoint.

## [0.1.1] - 2026-09-03

Analysis-only release. No API or behavior changes.

### Fixed

- The `unawaited_return_in_try_block` warning in `ServiceBase._getOnce`, which
  cost the package 20 pub points on the published 0.1.0. `dart analyze` is
  clean again.

## [0.1.0] - 2026-07-23

First stable release. Drops the `beta` tag and adds automatic retries, clearer
error mapping, and a working `related()`.

### Added

- Automatic retry with exponential backoff for transient failures (429, 5xx,
  network, and timeout), configurable through the new `RetryPolicy`. On by
  default with 3 retries; disable with `RetryPolicy.none()`. A server
  `Retry-After` on a 429 or 503 is honored, capped at `maxBackoff`.
- `WikiRequestException` for 4xx responses other than 404 and 429 (400, 401,
  403, ...). These used to surface as `WikiServerException`.
- `WikiServerException.retryAfter`, read from the `Retry-After` header on a 5xx.
- A live integration suite (`test/integration/`) that runs against the real
  Wikimedia API. Skipped by default; run it with
  `dart test --run-skipped --tags integration`. A nightly CI job runs it to
  catch upstream changes.

### Changed

- **Breaking:** `PagesClient.related()` now returns `List<SearchResultItem>`
  instead of `List<PageSummary>` and takes an optional `limit`. The REST
  `/page/related/` endpoint started returning 403, so `related()` is now built
  on the search endpoint's `morelike:` operator, which restores the feature.

### Fixed

- 4xx responses other than 404/429 were reported as `WikiServerException` with
  an "Unexpected status code" message; they now map to `WikiRequestException`.

## [0.1.0-beta.1] - 2026-06-29

First public release for testing and feedback.

### Added

- Project scaffold: directory structure, `pubspec.yaml`, `analysis_options.yaml`.
- `WikiProject` enum covering the supported Wikimedia projects.
- `WikiConfig` immutable settings object.
- `Endpoints` REST path constants.
- `UrlBuilder` for all URI construction.
- Sealed `WikiException` hierarchy: `WikiNetworkException`,
  `WikiTimeoutException`, `WikiNotFoundException`, `WikiRateLimitException`,
  `WikiServerException`, `WikiParseException`.
- `PageSummary`, `WikiThumbnail`, `ContentUrls` models.
- `SearchResponse`, `SearchResultItem` models.
- `MediaItem`, `MediaFile` models.
- `ServiceBase` mixin with the shared request lifecycle.
- `PagesClient` (`summary`, `html`, `related`), `SearchClient` (`pages`,
  `autocomplete`), `MediaClient` (`listForPage`, `getFile`).
- `WikiClient` entry point with named constructors and HTTP lifecycle handling.
- GitHub Actions CI, `UrlBuilder` tests, and model parsing tests.

