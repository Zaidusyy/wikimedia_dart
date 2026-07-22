# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

