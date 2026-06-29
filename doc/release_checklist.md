# Wikimedia Dart — Release Checklist

This document details the checklist to be executed before publishing new releases of the `wikimedia_dart` package.

## Pre-Release Checks

- **Package Metadata**:
  - Verify that `homepage`, `repository`, and `issue_tracker` in `pubspec.yaml` point to the correct URLs.
  - Verify that the package `description` is descriptive and accurate.
- **Version Verification**:
  - Verify that the `version` in `pubspec.yaml` is bumped correctly and adheres to Semantic Versioning.
  - Ensure all internal defaults or documentation referencing the version string are updated.
- **Changelog Verification**:
  - Ensure `CHANGELOG.md` has a new section for the target version, documenting all added, changed, deprecated, removed, or fixed behaviors.
  - Ensure the release date is documented.
- **README Verification**:
  - Verify that installation examples reference the correct package version.
  - Ensure any new features or limitations are documented.
- **License Verification**:
  - Ensure the copyright year and author name in the `LICENSE` file are up-to-date.
- **Example Verification**:
  - Run the example project locally to ensure it compiles and executes without error:
    `dart run example/main.dart`
- **User-Agent Verification**:
  - Ensure default User-Agent strings in the constructors match the new version format:
    `WikimediaDart/<version> (https://github.com/zaidsayyed/wikimedia_dart)`

## Quality Assurance & Verification

- **Format Check**:
  - Run `dart format .` to auto-format all code files.
  - Run `dart format --output=none --set-exit-if-changed .` to verify formatting compliance.
- **Static Analysis**:
  - Run `dart analyze --fatal-infos` to ensure zero compilation warnings, errors, or style hints.
- **Test Suite**:
  - Run `dart test` to execute the full unit and regression test suite. All tests must pass.
- **Coverage Generation**:
  - If required, run coverage analysis tools to ensure that test coverage remains at 100% (or meets repository minimum targets).
- **Pub Dry Run**:
  - Run `dart pub publish --dry-run` to ensure there are no package layout conventions or publishing warnings.

## Manual Smoke Tests

- Execute the live verification scenarios against the production Wikimedia REST APIs:
  - Wikipedia: query summaries, page HTML, search, and autocomplete.
  - Commons: query file metadata.
  - Wiktionary: query page HTML, search, and autocomplete.
  - Language overrides: query non-English language prefixes.
  - Verify that User-Agent headers are received and parsed without rate-limiting.
