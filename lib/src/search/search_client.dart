import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/search/search_response.dart';
import '../utils/url_builder.dart';

/// Search endpoints, reached through `wiki.search`.
class SearchClient with ServiceBase {
  /// Built by [WikiClient], which owns and shares [config] and [httpClient].
  SearchClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Full-text search for [query].
  ///
  /// [limit] caps the results (default 10, max 100). Pass [language] to search
  /// a different wiki edition just for this call.
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

  /// Returns article titles matching [prefix], for type-ahead UIs.
  ///
  /// Pass [language] to search a different wiki edition just for this call.
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
