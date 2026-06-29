import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/search/search_response.dart';
import '../utils/url_builder.dart';

/// Implements the `wiki.search.*` namespace.
///
/// Access this via [WikiClient.search] — do not instantiate directly.
class SearchClient with ServiceBase {
  /// Creates a [SearchClient].
  SearchClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Performs a full-text search and returns matching pages.
  ///
  /// [query] is the search term. [limit] controls the maximum number of
  /// results (default: 10, max: 100).
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  Future<SearchResponse> pages(
    String query, {
    int limit = 10,
    String? language,
  }) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: Endpoints.pageSearch,
      languageOverride: language,
      queryParameters: {
        'q': query,
        'limit': '$limit',
      },
    );
    return get(uri, SearchResponse.fromJson);
  }

  /// Returns a list of article titles matching the given prefix.
  ///
  /// Suitable for autocomplete / type-ahead search UIs.
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  Future<List<String>> autocomplete(
    String prefix, {
    int limit = 10,
    String? language,
  }) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: Endpoints.pageTitle,
      languageOverride: language,
      queryParameters: {
        'q': prefix,
        'limit': '$limit',
      },
    );
    return get(
      uri,
      (json) => (json['pages'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['title'] as String)
          .toList(),
    );
  }
}
