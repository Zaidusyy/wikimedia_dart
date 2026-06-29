import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/pages/page_summary.dart';
import '../utils/url_builder.dart';

/// Implements the `wiki.pages.*` namespace.
///
/// Access this via [WikiClient.pages] — do not instantiate directly.
class PagesClient with ServiceBase {
  /// Creates a [PagesClient].
  ///
  /// Both [config] and [httpClient] are owned by [WikiClient] and
  /// shared across all service clients.
  PagesClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Returns the summary for an article with the given [title].
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  ///
  /// Throws [WikiNotFoundException] if the article does not exist.
  /// Throws [WikiRateLimitException] if the rate limit is exceeded.
  /// Throws [WikiNetworkException] on connectivity failures.
  /// Throws [WikiParseException] if the response cannot be parsed.
  Future<PageSummary> summary(String title, {String? language}) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageSummary}/${Uri.encodeComponent(title)}',
      languageOverride: language,
    );
    return get(uri, PageSummary.fromJson);
  }

  /// Returns the full HTML content of the article with the given [title].
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  Future<String> html(String title, {String? language}) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageHtml}/${Uri.encodeComponent(title)}',
      languageOverride: language,
    );
    return getRaw(uri);
  }

  /// Returns a list of articles related to the article with [title].
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  Future<List<PageSummary>> related(String title, {String? language}) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageRelated}/${Uri.encodeComponent(title)}',
      languageOverride: language,
    );
    return get(
      uri,
      (json) => (json['pages'] as List<dynamic>)
          .map((e) => PageSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
