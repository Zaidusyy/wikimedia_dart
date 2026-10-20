import 'package:meta/meta.dart';

import '../common/wiki_thumbnail.dart';

/// A single search result item returned by the Wikimedia REST API.
@immutable
class SearchResultItem {
  /// Creates a [SearchResultItem].
  const SearchResultItem({
    required this.title,
    required this.pageId,
    this.description,
    this.excerpt,
    this.thumbnail,
  });

  /// Article title with spaces.
  final String title;

  /// Wikimedia page identifier.
  final int pageId;

  /// Short description of the article.
  final String? description;

  /// Highlighted excerpt matching the search query.
  final String? excerpt;

  /// Thumbnail image for this result.
  final WikiThumbnail? thumbnail;

  /// Parses a [SearchResultItem] from the API's JSON.
  factory SearchResultItem.fromJson(Map<String, dynamic> json) =>
      SearchResultItem(
        title: json['title'] as String,
        pageId: (json['id'] ?? json['pageid']) as int,
        description: json['description'] as String?,
        excerpt: json['excerpt'] as String?,
        thumbnail: json['thumbnail'] != null
            ? WikiThumbnail.fromJson(
                json['thumbnail'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts this result back to the API's JSON shape.
  ///
  /// Round-trips through [SearchResultItem.fromJson]. Null fields are
  /// omitted. The page id is written as `id`, the key the search endpoint
  /// uses.
  Map<String, dynamic> toJson() => {
        'title': title,
        'id': pageId,
        if (description != null) 'description': description,
        if (excerpt != null) 'excerpt': excerpt,
        if (thumbnail != null) 'thumbnail': thumbnail!.toJson(),
      };

  /// Returns a copy of this [SearchResultItem] with the given fields replaced.
  SearchResultItem copyWith({
    String? title,
    int? pageId,
    String? description,
    String? excerpt,
    WikiThumbnail? thumbnail,
  }) =>
      SearchResultItem(
        title: title ?? this.title,
        pageId: pageId ?? this.pageId,
        description: description ?? this.description,
        excerpt: excerpt ?? this.excerpt,
        thumbnail: thumbnail ?? this.thumbnail,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          pageId == other.pageId &&
          description == other.description &&
          excerpt == other.excerpt &&
          thumbnail == other.thumbnail;

  @override
  int get hashCode =>
      Object.hash(title, pageId, description, excerpt, thumbnail);

  @override
  String toString() => 'SearchResultItem(title: $title, pageId: $pageId)';
}
