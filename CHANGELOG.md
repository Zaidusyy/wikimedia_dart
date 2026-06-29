# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project scaffold: full directory structure, `pubspec.yaml`, `analysis_options.yaml`
- `WikiProject` enum with all supported Wikimedia projects
- `WikiConfig` immutable value object
- `Endpoints` REST path constants
- `UrlBuilder` for all URI construction logic
- Sealed `WikiException` hierarchy: `WikiNetworkException`, `WikiTimeoutException`,
  `WikiNotFoundException`, `WikiRateLimitException`, `WikiServerException`,
  `WikiParseException`
- `PageSummary`, `WikiThumbnail`, `ContentUrls` models
- `SearchResponse`, `SearchResultItem` models
- `MediaItem`, `MediaFile` models
- `ServiceBase` mixin with shared request lifecycle
- `PagesClient` implementing `pages.summary()`, `pages.html()`, `pages.related()`
- `SearchClient` implementing `search.pages()`, `search.autocomplete()`
- `MediaClient` implementing `media.listForPage()`, `media.getFile()`
- `WikiClient` entry point with named constructors and HTTP lifecycle management
- GitHub Actions CI workflow
- Exhaustive `UrlBuilder` tests
- Model parsing tests for all models

## [0.1.0-beta.1] — 2026-06-29

Initial public release candidate of Wikimedia Dart for beta testing and real-world feedback.

