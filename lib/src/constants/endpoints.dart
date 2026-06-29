/// REST API path constants for the Wikimedia REST v1 API.
///
/// All paths must begin with a `/` and are appended after `/api/rest_v1`
/// by [UrlBuilder]. Verify each path against the live API documentation:
/// https://www.mediawiki.org/wiki/Wikimedia_REST_API
abstract final class Endpoints {
  /// `GET /page/summary/{title}` — Article summary with extract and thumbnail.
  static const String pageSummary = '/page/summary';

  /// `GET /page/html/{title}` — Full HTML content of an article.
  static const String pageHtml = '/page/html';

  /// `GET /page/related/{title}` — Articles related to a given article.
  static const String pageRelated = '/page/related';

  /// `GET /page/media-list/{title}` — All media embedded in an article.
  static const String pageMediaList = '/page/media-list';

  /// `GET /search/page` — Full-text search across the project.
  static const String pageSearch = '/search/page';

  /// `GET /search/title` — Title prefix / autocomplete search.
  static const String pageTitle = '/search/title';
}
