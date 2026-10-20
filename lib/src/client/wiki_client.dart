import 'package:http/http.dart' as http;

import '../constants/version.dart';
import '../media/media_client.dart';
import '../models/common/wiki_project.dart';
import '../pages/pages_client.dart';
import '../search/search_client.dart';
import 'retry_policy.dart';
import 'wiki_config.dart';

/// The entry point for the package.
///
/// Create one [WikiClient] per project/language and reuse it; each instance
/// keeps a single HTTP connection pool. Call [close] when you're done to free
/// it.
///
/// ## Quick start
///
/// ```dart
/// final wiki = WikiClient.wikipedia();
/// final summary = await wiki.pages.summary('Earth');
/// print(summary.extract);
/// wiki.close();
/// ```
///
/// ## Named constructors
///
/// | Constructor | Project | Language |
/// |---|---|---|
/// | [WikiClient.wikipedia] | Wikipedia | Configurable (default: `'en'`) |
/// | [WikiClient.wiktionary] | Wiktionary | Configurable |
/// | [WikiClient.commons] | Wikimedia Commons | Not used |
/// | [WikiClient.custom] | A self-hosted MediaWiki | Not used |
///
/// The per-call `language:` override works the same way: it picks the
/// subdomain, so Commons, Wikidata and custom clients ignore it.
class WikiClient {
  /// Creates a [WikiClient] with full explicit configuration.
  ///
  /// Prefer the named constructors for standard Wikimedia projects.
  WikiClient({
    String language = 'en',
    WikiProject project = WikiProject.wikipedia,
    Duration timeout = const Duration(seconds: 30),
    String userAgent = defaultUserAgent,
    String? customBaseUrl,
    String customRestBasePath = '/rest.php/v1',
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
  })  : _config = WikiConfig(
          language: language,
          project: project,
          timeout: timeout,
          userAgent: userAgent,
          customBaseUrl: customBaseUrl,
          customRestBasePath: customRestBasePath,
          retryPolicy: retryPolicy,
        ),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  WikiClient._internal({
    required WikiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  /// Creates a [WikiClient] targeting Wikipedia.
  ///
  /// [language] is the wiki's subdomain and defaults to `'en'` (English
  /// Wikipedia). Pass another one, such as `'fr'` or `'simple'`, to target a
  /// different edition.
  factory WikiClient.wikipedia({
    String language = 'en',
    Duration timeout = const Duration(seconds: 30),
    String userAgent = defaultUserAgent,
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: WikiProject.wikipedia,
          timeout: timeout,
          userAgent: userAgent,
          retryPolicy: retryPolicy,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting Wiktionary.
  factory WikiClient.wiktionary({
    String language = 'en',
    Duration timeout = const Duration(seconds: 30),
    String userAgent = defaultUserAgent,
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: WikiProject.wiktionary,
          timeout: timeout,
          userAgent: userAgent,
          retryPolicy: retryPolicy,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting Wikimedia Commons.
  ///
  /// Commons does not use a language prefix.
  factory WikiClient.commons({
    Duration timeout = const Duration(seconds: 30),
    String userAgent = defaultUserAgent,
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: 'en', // Unused for Commons but required by WikiConfig.
          project: WikiProject.commons,
          timeout: timeout,
          userAgent: userAgent,
          retryPolicy: retryPolicy,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting a custom / self-hosted MediaWiki
  /// installation.
  ///
  /// [baseUrl] is where MediaWiki is served from. Its scheme, host, port, and
  /// path prefix are all kept, so all of these work:
  ///
  /// ```dart
  /// WikiClient.custom(baseUrl: 'https://wiki.example.org');
  /// WikiClient.custom(baseUrl: 'https://example.org/w');
  /// WikiClient.custom(baseUrl: 'http://localhost:8080');
  /// ```
  ///
  /// Requests go to `{baseUrl}{restBasePath}{endpoint}`. [restBasePath]
  /// defaults to `'/rest.php/v1'`, where MediaWiki core serves its REST API.
  /// Pass `'/api/rest_v1'` for a host running RESTBase, as Wikimedia's own
  /// wikis do.
  ///
  /// On a stock MediaWiki only search works: [SearchClient], and
  /// [PagesClient.related] if the wiki runs CirrusSearch. Summaries, HTML and
  /// media lists use RESTBase paths, so they return 404 there.
  ///
  /// [language] and [project] are recorded on the config but don't change
  /// the URL, since [baseUrl] supplies the host.
  factory WikiClient.custom({
    required String baseUrl,
    String language = 'en',
    WikiProject project = WikiProject.wikipedia,
    String restBasePath = '/rest.php/v1',
    Duration timeout = const Duration(seconds: 30),
    String userAgent = defaultUserAgent,
    RetryPolicy retryPolicy = const RetryPolicy(),
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: project,
          timeout: timeout,
          userAgent: userAgent,
          customBaseUrl: baseUrl,
          customRestBasePath: restBasePath,
          retryPolicy: retryPolicy,
        ),
        httpClient: httpClient,
      );

  final WikiConfig _config;
  final http.Client _httpClient;

  /// `true` when this client created its own [http.Client] and is
  /// responsible for closing it.
  final bool _ownsHttpClient;

  bool _closed = false;

  /// The pages service. Access via `wiki.pages.summary('Earth')`.
  late final PagesClient pages =
      PagesClient(_config, _httpClient, () => _closed);

  /// The search service. Access via `wiki.search.pages('query')`.
  late final SearchClient search =
      SearchClient(_config, _httpClient, () => _closed);

  /// The media service. Access via `wiki.media.listForPage('Earth')`.
  late final MediaClient media =
      MediaClient(_config, _httpClient, () => _closed);

  /// Closes this client and releases all resources.
  ///
  /// After calling [close], any attempt to use a service method will
  /// throw a [StateError]. A call already in progress stops retrying and
  /// fails with its last error.
  ///
  /// If an [http.Client] was supplied at construction the caller retains
  /// ownership and is responsible for closing it. Wikimedia Dart will only
  /// close an [http.Client] that it created itself.
  ///
  /// Calling [close] multiple times is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
