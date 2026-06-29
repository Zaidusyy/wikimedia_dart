import 'package:meta/meta.dart';

import '../common/content_urls.dart';
import '../common/wiki_thumbnail.dart';

/// A summary of a Wikimedia article, as returned by the
/// `GET /api/rest_v1/page/summary/{title}` endpoint.
@immutable
class PageSummary {
  /// Creates a [PageSummary].
  const PageSummary({
    required this.title,
    required this.displayTitle,
    required this.pageId,
    required this.language,
    this.description,
    this.extract,
    this.extractHtml,
    this.thumbnail,
    this.contentUrls,
    this.wikidataId,
    this.lastModified,
  });

  /// Canonical article title, e.g. `'Earth'`.
  final String title;

  /// HTML-formatted display title, e.g. `'<i>Earth</i>'`.
  final String displayTitle;

  /// Wikimedia page identifier.
  final int pageId;

  /// BCP 47 language code of this article, e.g. `'en'`.
  final String language;

  /// Short description of the article, e.g. `'Third planet from the Sun'`.
  final String? description;

  /// Plain-text extract (may be truncated for long articles).
  final String? extract;

  /// HTML version of the extract.
  final String? extractHtml;

  /// Thumbnail image for the article.
  final WikiThumbnail? thumbnail;

  /// Desktop and mobile article page URLs.
  final ContentUrls? contentUrls;

  /// Wikidata item ID, e.g. `'Q2'`.
  final String? wikidataId;

  /// Date and time the article was last modified.
  final DateTime? lastModified;

  /// Deserialises a [PageSummary] from a JSON map.
  factory PageSummary.fromJson(Map<String, dynamic> json) => PageSummary(
        title: json['title'] as String,
        displayTitle: json['displaytitle'] as String,
        pageId: json['pageid'] as int,
        language: json['lang'] as String,
        description: json['description'] as String?,
        extract: json['extract'] as String?,
        extractHtml: json['extract_html'] as String?,
        thumbnail: json['thumbnail'] != null
            ? WikiThumbnail.fromJson(
                json['thumbnail'] as Map<String, dynamic>,
              )
            : null,
        contentUrls: json['content_urls'] != null
            ? ContentUrls.fromJson(
                json['content_urls'] as Map<String, dynamic>,
              )
            : null,
        wikidataId: json['wikibase_item'] as String?,
        lastModified: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );

  /// Returns a copy of this [PageSummary] with the given fields replaced.
  PageSummary copyWith({
    String? title,
    String? displayTitle,
    int? pageId,
    String? language,
    String? description,
    String? extract,
    String? extractHtml,
    WikiThumbnail? thumbnail,
    ContentUrls? contentUrls,
    String? wikidataId,
    DateTime? lastModified,
  }) =>
      PageSummary(
        title: title ?? this.title,
        displayTitle: displayTitle ?? this.displayTitle,
        pageId: pageId ?? this.pageId,
        language: language ?? this.language,
        description: description ?? this.description,
        extract: extract ?? this.extract,
        extractHtml: extractHtml ?? this.extractHtml,
        thumbnail: thumbnail ?? this.thumbnail,
        contentUrls: contentUrls ?? this.contentUrls,
        wikidataId: wikidataId ?? this.wikidataId,
        lastModified: lastModified ?? this.lastModified,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSummary &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          displayTitle == other.displayTitle &&
          pageId == other.pageId &&
          language == other.language &&
          description == other.description &&
          extract == other.extract &&
          extractHtml == other.extractHtml &&
          thumbnail == other.thumbnail &&
          contentUrls == other.contentUrls &&
          wikidataId == other.wikidataId &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hash(
        title,
        displayTitle,
        pageId,
        language,
        description,
        extract,
        extractHtml,
        thumbnail,
        contentUrls,
        wikidataId,
        lastModified,
      );

  @override
  String toString() => 'PageSummary(title: $title, pageId: $pageId, '
      'language: $language)';
}
