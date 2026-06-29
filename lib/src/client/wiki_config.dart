import 'package:meta/meta.dart';

import '../models/common/wiki_project.dart';

/// Immutable configuration value object for a [WikiClient] instance.
///
/// This class centralises all per-client settings. No service class
/// stores configuration independently; they all hold a reference to
/// this shared object.
@immutable
final class WikiConfig {
  /// Creates a [WikiConfig].
  const WikiConfig({
    required this.language,
    required this.project,
    required this.timeout,
    required this.userAgent,
    this.customBaseUrl,
  });

  /// BCP 47 language code, e.g. `'en'`, `'fr'`, `'zh'`.
  final String language;

  /// The Wikimedia project this client is targeting.
  final WikiProject project;

  /// Maximum duration to wait for a single HTTP response.
  final Duration timeout;

  /// Value sent in the `User-Agent` request header.
  ///
  /// Wikimedia's API terms of service require a descriptive User-Agent.
  /// See https://www.mediawiki.org/wiki/API:Etiquette
  final String userAgent;

  /// Base URL for custom / self-hosted MediaWiki installations.
  ///
  /// `null` for all standard Wikimedia-hosted projects.
  final String? customBaseUrl;

  /// Resolves the effective language for a request.
  ///
  /// If [override] is non-null it takes precedence over [language].
  /// This allows per-call language switching without creating a new client.
  String resolveLanguage(String? override) => override ?? language;
}
