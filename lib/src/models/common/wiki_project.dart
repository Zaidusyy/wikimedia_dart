/// The Wikimedia projects this package can target.
///
/// Pass one to [WikiClient], via a named constructor or directly, to pick
/// which API host requests go to.
enum WikiProject {
  /// Wikipedia (https://wikipedia.org).
  wikipedia,

  /// Wikimedia Commons (https://commons.wikimedia.org). No language prefix.
  commons,

  /// Wiktionary (https://wiktionary.org).
  wiktionary,

  /// Wikibooks (https://wikibooks.org).
  wikibooks,

  /// Wikinews (https://wikinews.org).
  wikinews,

  /// Wikisource (https://wikisource.org).
  wikisource,

  /// Wikivoyage (https://wikivoyage.org).
  wikivoyage,

  /// Wikidata (https://wikidata.org). No language prefix.
  wikidata;

  /// The base domain for this project.
  ///
  /// For language-prefixed projects this is the bare domain and [UrlBuilder]
  /// adds the prefix. For single-instance projects it's the full host.
  String get baseDomain => switch (this) {
        WikiProject.commons => 'commons.wikimedia.org',
        WikiProject.wikidata => 'www.wikidata.org',
        _ => '$name.org',
      };

  /// Whether the hostname gets a language prefix.
  ///
  /// False for the single global instances (Commons, Wikidata), true
  /// otherwise.
  bool get supportsLanguagePrefix => switch (this) {
        WikiProject.commons => false,
        WikiProject.wikidata => false,
        _ => true,
      };
}
