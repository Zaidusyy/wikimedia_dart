/// Enum of Wikimedia projects supported by Wikimedia Dart.
///
/// Each value corresponds to a distinct Wikimedia-hosted project.
/// Pass this to [WikiClient] (via named constructors or directly) to
/// target the appropriate API endpoint.
enum WikiProject {
  /// English / multilingual Wikipedia — https://wikipedia.org
  wikipedia,

  /// Wikimedia Commons — https://commons.wikimedia.org
  /// Note: Commons does not use a language prefix.
  commons,

  /// Wiktionary — https://wiktionary.org
  wiktionary,

  /// Wikibooks — https://wikibooks.org
  wikibooks,

  /// Wikinews — https://wikinews.org
  wikinews,

  /// Wikisource — https://wikisource.org
  wikisource,

  /// Wikivoyage — https://wikivoyage.org
  wikivoyage,

  /// Wikidata — https://wikidata.org
  /// Note: Wikidata does not use a language prefix.
  wikidata;

  /// The base domain for this project.
  ///
  /// For projects that support a language prefix the domain does not
  /// include the prefix — [UrlBuilder] prepends it. For projects with a
  /// single global instance the full hostname is returned.
  String get baseDomain => switch (this) {
        WikiProject.commons => 'commons.wikimedia.org',
        WikiProject.wikidata => 'www.wikidata.org',
        _ => '$name.org',
      };

  /// Whether a language prefix is prepended to the hostname.
  ///
  /// `false` for projects with a single global instance (Commons,
  /// Wikidata). `true` for all other projects.
  bool get supportsLanguagePrefix => switch (this) {
        WikiProject.commons => false,
        WikiProject.wikidata => false,
        _ => true,
      };
}
