import '../client/wiki_config.dart';

/// Builds request URIs. Keeping this in one place means a change to the
/// Wikimedia base path only has to happen here.
abstract final class UrlBuilder {
  /// Builds a full request [Uri].
  ///
  /// [path] must start with `/`; use the [Endpoints] constants for it. It's
  /// placed under the REST base path (or the search base path for `/search/`
  /// routes). [languageOverride], when set, wins over `config.language` so a
  /// single call can hit a different edition. [queryParameters] become the
  /// query string when non-empty.
  ///
  /// Example:
  /// ```dart
  /// final uri = UrlBuilder.build(
  ///   config: config,
  ///   path: '${Endpoints.pageSummary}/${Uri.encodeComponent('New York City')}',
  /// );
  /// // gives https://en.wikipedia.org/api/rest_v1/page/summary/New%20York%20City
  /// ```
  static Uri build({
    required WikiConfig config,
    required String path,
    String? languageOverride,
    Map<String, String>? queryParameters,
  }) {
    final language = config.resolveLanguage(languageOverride);
    final host = _resolveHost(config, language);
    // Search lives under a different base path than the REST content API.
    // TODO(v0.2): route by endpoint metadata instead of sniffing the prefix.
    final basePath =
        path.startsWith('/search/') ? '/w/rest.php/v1' : '/api/rest_v1';
    // Build the Uri by hand rather than with Uri.https(): the latter re-encodes
    // '%' and would double-encode titles we've already percent-encoded.
    return Uri(
      scheme: 'https',
      host: host,
      path: '$basePath$path',
      queryParameters:
          queryParameters?.isEmpty ?? true ? null : queryParameters,
    );
  }

  static String _resolveHost(WikiConfig config, String language) {
    // Self-hosted MediaWiki: take the host straight from the custom URL.
    if (config.customBaseUrl != null) {
      return Uri.parse(config.customBaseUrl!).host;
    }
    // Commons and Wikidata have no language prefix.
    if (!config.project.supportsLanguagePrefix) {
      return config.project.baseDomain;
    }
    // Everything else: {lang}.{project}.org, e.g. en.wikipedia.org
    return '$language.${config.project.baseDomain}';
  }
}
