import '../client/wiki_config.dart';

/// Constructs validated [Uri] instances for Wikimedia REST API requests.
///
/// All URL construction logic lives here. No service class constructs
/// URIs directly. If the Wikimedia API changes its base path, there is
/// exactly one file to update.
abstract final class UrlBuilder {
  /// Builds a fully qualified [Uri] for a Wikimedia REST API request.
  ///
  /// The path must start with `/` and will be appended to
  /// `/api/rest_v1`. Use [Endpoints] constants for the path segments.
  ///
  /// [languageOverride] takes precedence over [config.language] if
  /// provided, enabling per-call language switching.
  ///
  /// [queryParameters] are appended as the URI query string when present.
  ///
  /// Example:
  /// ```dart
  /// final uri = UrlBuilder.build(
  ///   config: config,
  ///   path: '${Endpoints.pageSummary}/${Uri.encodeComponent('New York City')}',
  /// );
  /// // → https://en.wikipedia.org/api/rest_v1/page/summary/New%20York%20City
  /// ```
  static Uri build({
    required WikiConfig config,
    required String path,
    String? languageOverride,
    Map<String, String>? queryParameters,
  }) {
    final language = config.resolveLanguage(languageOverride);
    final host = _resolveHost(config, language);
    // TODO: Path-prefix routing is a short-term workaround for v0.1.
    // Replace this with explicit endpoint-family metadata in a future version.
    final basePath =
        path.startsWith('/search/') ? '/w/rest.php/v1' : '/api/rest_v1';
    // Use Uri() instead of Uri.https() to avoid double-encoding:
    // Uri.https() normalises the path and re-encodes % characters,
    // which corrupts titles pre-encoded with Uri.encodeComponent().
    return Uri(
      scheme: 'https',
      host: host,
      path: '$basePath$path',
      queryParameters:
          queryParameters?.isEmpty ?? true ? null : queryParameters,
    );
  }

  static String _resolveHost(WikiConfig config, String language) {
    // Custom MediaWiki installations — use the host from customBaseUrl.
    if (config.customBaseUrl != null) {
      return Uri.parse(config.customBaseUrl!).host;
    }
    // Projects without a language prefix (Commons, Wikidata).
    if (!config.project.supportsLanguagePrefix) {
      return config.project.baseDomain;
    }
    // Standard pattern: {lang}.{project}.org  e.g. en.wikipedia.org
    return '$language.${config.project.baseDomain}';
  }
}
