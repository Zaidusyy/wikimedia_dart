import 'package:http/http.dart' as http;

import '../media/media_client.dart';
import '../models/common/wiki_project.dart';
import '../pages/pages_client.dart';
import '../search/search_client.dart';
import 'wiki_config.dart';

/// The primary entry point for the Wikimedia Dart SDK.
///
/// Create one [WikiClient] per app (or per logical project/language
/// combination) and reuse it across requests. A single client instance
/// shares one HTTP connection pool.
///
/// **Always call [close] when finished to release resources.**
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
/// | [WikiClient.commons] | Wikimedia Commons | N/A |
/// | [WikiClient.custom] | Any MediaWiki | Configurable |
class WikiClient {
  /// Creates a [WikiClient] with full explicit configuration.
  ///
  /// Prefer the named constructors for standard Wikimedia projects.
  WikiClient({
    String language = 'en',
    WikiProject project = WikiProject.wikipedia,
    Duration timeout = const Duration(seconds: 30),
    String userAgent =
        'WikimediaDart/0.1.0 (https://github.com/zaidsayyed/wikimedia_dart)',
    String? customBaseUrl,
    http.Client? httpClient,
  })  : _config = WikiConfig(
          language: language,
          project: project,
          timeout: timeout,
          userAgent: userAgent,
          customBaseUrl: customBaseUrl,
        ),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  WikiClient._internal({
    required WikiConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  // ---------------------------------------------------------------------------
  // Named constructors
  // ---------------------------------------------------------------------------

  /// Creates a [WikiClient] targeting Wikipedia.
  ///
  /// [language] defaults to `'en'` (English Wikipedia). Pass any BCP 47
  /// language code to target a different Wikipedia edition.
  factory WikiClient.wikipedia({
    String language = 'en',
    Duration timeout = const Duration(seconds: 30),
    String userAgent =
        'WikimediaDart/0.1.0-beta.1 (https://github.com/zaidsayyed/wikimedia_dart)',
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: WikiProject.wikipedia,
          timeout: timeout,
          userAgent: userAgent,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting Wiktionary.
  factory WikiClient.wiktionary({
    String language = 'en',
    Duration timeout = const Duration(seconds: 30),
    String userAgent =
        'WikimediaDart/0.1.0-beta.1 (https://github.com/zaidsayyed/wikimedia_dart)',
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: WikiProject.wiktionary,
          timeout: timeout,
          userAgent: userAgent,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting Wikimedia Commons.
  ///
  /// Commons does not use a language prefix.
  factory WikiClient.commons({
    Duration timeout = const Duration(seconds: 30),
    String userAgent =
        'WikimediaDart/0.1.0-beta.1 (https://github.com/zaidsayyed/wikimedia_dart)',
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: 'en', // Unused for Commons but required by WikiConfig.
          project: WikiProject.commons,
          timeout: timeout,
          userAgent: userAgent,
        ),
        httpClient: httpClient,
      );

  /// Creates a [WikiClient] targeting a custom / self-hosted MediaWiki
  /// installation.
  ///
  /// [baseUrl] must be the root URL of the MediaWiki installation, e.g.
  /// `'https://wiki.example.org'`.
  factory WikiClient.custom({
    required String baseUrl,
    String language = 'en',
    Duration timeout = const Duration(seconds: 30),
    String userAgent =
        'WikimediaDart/0.1.0-beta.1 (https://github.com/zaidsayyed/wikimedia_dart)',
    http.Client? httpClient,
  }) =>
      WikiClient._internal(
        config: WikiConfig(
          language: language,
          project: WikiProject.wikipedia,
          timeout: timeout,
          userAgent: userAgent,
          customBaseUrl: baseUrl,
        ),
        httpClient: httpClient,
      );

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  final WikiConfig _config;
  final http.Client _httpClient;

  /// `true` when this client created its own [http.Client] and is
  /// responsible for closing it.
  final bool _ownsHttpClient;

  bool _closed = false;

  // ---------------------------------------------------------------------------
  // Service getters (lazy, created once on first access)
  // ---------------------------------------------------------------------------

  /// The pages service. Access via `wiki.pages.summary('Earth')`.
  late final PagesClient pages =
      PagesClient(_config, _httpClient, () => _closed);

  /// The search service. Access via `wiki.search.pages('query')`.
  late final SearchClient search =
      SearchClient(_config, _httpClient, () => _closed);

  /// The media service. Access via `wiki.media.listForPage('Earth')`.
  late final MediaClient media =
      MediaClient(_config, _httpClient, () => _closed);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Closes this client and releases all resources.
  ///
  /// After calling [close], any attempt to use a service method will
  /// throw a [StateError].
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
