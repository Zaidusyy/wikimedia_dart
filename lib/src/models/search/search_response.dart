import 'package:meta/meta.dart';

import 'search_result_item.dart';

/// The result of a full-text search via the Wikimedia REST API.
///
/// Returned by [SearchClient.pages].
@immutable
class SearchResponse {
  /// Creates a [SearchResponse].
  const SearchResponse({required this.pages, this.nextCursor});

  /// The list of search result items matching the query.
  final List<SearchResultItem> pages;

  /// Pagination cursor for the next page of results.
  ///
  /// `null` in v0.1 — pagination is a v0.2+ feature. The field is
  /// present in the model now to avoid a breaking change later.
  final String? nextCursor;

  /// Deserialises a [SearchResponse] from a JSON map.
  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        pages: (json['pages'] as List<dynamic>)
            .map(
              (e) => SearchResultItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextCursor: json['next'] as String?,
      );

  /// Returns a copy of this [SearchResponse] with the given fields replaced.
  SearchResponse copyWith({
    List<SearchResultItem>? pages,
    String? nextCursor,
  }) =>
      SearchResponse(
        pages: pages ?? this.pages,
        nextCursor: nextCursor ?? this.nextCursor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResponse &&
          runtimeType == other.runtimeType &&
          pages == other.pages &&
          nextCursor == other.nextCursor;

  @override
  int get hashCode => Object.hash(pages, nextCursor);

  @override
  String toString() =>
      'SearchResponse(pages: ${pages.length} items, nextCursor: $nextCursor)';
}
