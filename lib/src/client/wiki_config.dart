import 'package:meta/meta.dart';

import '../models/common/wiki_project.dart';
import 'retry_policy.dart';

/// Immutable settings for a [WikiClient].
///
/// One instance is shared by all of a client's service objects, so they
/// always agree on language, timeout, and the rest.
@immutable
final class WikiConfig {
  /// Creates a [WikiConfig].
  const WikiConfig({
    required this.language,
    required this.project,
    required this.timeout,
    required this.userAgent,
    this.customBaseUrl,
    this.retryPolicy = const RetryPolicy(),
  });

  /// BCP 47 language code, e.g. `'en'`, `'fr'`, `'zh'`.
  final String language;

  /// The Wikimedia project this client is targeting.
  final WikiProject project;

  /// Maximum duration to wait for a single HTTP response.
  final Duration timeout;

  /// Value sent in the `User-Agent` request header.
  ///
  /// Wikimedia asks every client to send a descriptive User-Agent; see
  /// https://www.mediawiki.org/wiki/API:Etiquette
  final String userAgent;

  /// Base URL for custom / self-hosted MediaWiki installations.
  ///
  /// `null` for all standard Wikimedia-hosted projects.
  final String? customBaseUrl;

  /// Governs automatic retry of transient request failures.
  ///
  /// Defaults to [RetryPolicy] with 3 retries and exponential backoff.
  /// Use [RetryPolicy.none] to disable retries.
  final RetryPolicy retryPolicy;

  /// The language to use for a request: [override] if given, otherwise
  /// [language]. Lets a single call target a different wiki edition.
  String resolveLanguage(String? override) => override ?? language;
}
