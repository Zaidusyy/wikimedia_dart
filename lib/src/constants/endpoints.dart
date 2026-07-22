/// REST paths for the Wikimedia API.
///
/// Each starts with `/` and is joined onto the base path by [UrlBuilder].
/// Reference: https://www.mediawiki.org/wiki/Wikimedia_REST_API
abstract final class Endpoints {
  /// `GET /page/summary/{title}`: summary with extract and thumbnail.
  static const String pageSummary = '/page/summary';

  /// `GET /page/html/{title}`: full article HTML.
  static const String pageHtml = '/page/html';

  /// `GET /page/media-list/{title}`: media embedded in an article.
  static const String pageMediaList = '/page/media-list';

  /// `GET /search/page`: full-text search.
  static const String pageSearch = '/search/page';

  /// `GET /search/title`: title prefix / autocomplete search.
  static const String pageTitle = '/search/title';
}
