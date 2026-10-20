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

  /// Cursor for the next page of results.
  ///
  /// Always `null` for now; pagination lands in a later version. It's here
  /// already so adding it won't be a breaking change.
  final String? nextCursor;

  /// Parses a [SearchResponse] from the API's JSON.
  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        pages: (json['pages'] as List<dynamic>)
            .map(
              (e) => SearchResultItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextCursor: json['next'] as String?,
      );

  /// Converts this response back to the API's JSON shape.
  ///
  /// Round-trips through [SearchResponse.fromJson].
  Map<String, dynamic> toJson() => {
        'pages': pages.map((p) => p.toJson()).toList(),
        if (nextCursor != null) 'next': nextCursor,
      };

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
          _pagesEqual(pages, other.pages) &&
          nextCursor == other.nextCursor;

  @override
  int get hashCode => Object.hash(Object.hashAll(pages), nextCursor);

  /// Compares [pages] element by element.
  ///
  /// `List` uses identity equality, so two responses carrying equal items in
  /// separate lists would otherwise compare unequal.
  static bool _pagesEqual(
    List<SearchResultItem> a,
    List<SearchResultItem> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'SearchResponse(pages: ${pages.length} items, nextCursor: $nextCursor)';
}
