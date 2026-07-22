import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/pages/page_summary.dart';
import '../models/search/search_response.dart';
import '../models/search/search_result_item.dart';
import '../utils/url_builder.dart';

/// Page endpoints, reached through `wiki.pages`.
class PagesClient with ServiceBase {
  /// Built by [WikiClient], which owns and shares [config] and [httpClient].
  PagesClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Fetches the summary (extract, thumbnail, links) for [title].
  ///
  /// Pass [language] to hit a different wiki edition just for this call.
  /// Throws [WikiNotFoundException] when the article doesn't exist, and the
  /// other [WikiException] subtypes on rate limits, network, or parse errors.
  Future<PageSummary> summary(String title, {String? language}) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageSummary}/${Uri.encodeComponent(title)}',
      languageOverride: language,
    );
    return get(uri, PageSummary.fromJson);
  }

  /// Returns the article's full HTML for [title].
  ///
  /// Pass [language] to hit a different wiki edition just for this call.
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
  /// Implemented via the search endpoint's `morelike:` operator, which
  /// surfaces pages textually similar to [title]. The Wikimedia REST
  /// `/page/related/` endpoint was restricted upstream (HTTP 403) and is no
  /// longer usable, so this method uses "more like this" search instead.
  ///
  /// [limit] controls the maximum number of related pages (default: 10).
  /// [language] overrides the client's default language for this request
  /// only.
  Future<List<SearchResultItem>> related(
    String title, {
    int limit = 10,
    String? language,
  }) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: Endpoints.pageSearch,
      languageOverride: language,
      queryParameters: {
        'q': 'morelike:$title',
        'limit': '$limit',
      },
    );
    return get(uri, (json) => SearchResponse.fromJson(json).pages);
  }
}
