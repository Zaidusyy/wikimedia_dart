import 'package:meta/meta.dart';

/// Desktop and mobile article page URLs for a Wikimedia article.
@immutable
class ContentUrls {
  /// Creates a [ContentUrls].
  const ContentUrls({
    required this.desktopUrl,
    required this.mobileUrl,
  });

  /// URL to the article's desktop web page.
  final String desktopUrl;

  /// URL to the article's mobile web page.
  final String mobileUrl;

  /// Deserialises a [ContentUrls] from a JSON map.
  ///
  /// Expects the shape returned by the Wikimedia REST API's
  /// `content_urls` field:
  /// ```json
  /// {
  ///   "desktop": { "page": "https://en.wikipedia.org/wiki/Earth" },
  ///   "mobile":  { "page": "https://en.m.wikipedia.org/wiki/Earth" }
  /// }
  /// ```
  factory ContentUrls.fromJson(Map<String, dynamic> json) => ContentUrls(
        desktopUrl: (json['desktop'] as Map<String, dynamic>)['page'] as String,
        mobileUrl: (json['mobile'] as Map<String, dynamic>)['page'] as String,
      );

  /// Returns a copy of this [ContentUrls] with the given fields replaced.
  ContentUrls copyWith({
    String? desktopUrl,
    String? mobileUrl,
  }) =>
      ContentUrls(
        desktopUrl: desktopUrl ?? this.desktopUrl,
        mobileUrl: mobileUrl ?? this.mobileUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentUrls &&
          runtimeType == other.runtimeType &&
          desktopUrl == other.desktopUrl &&
          mobileUrl == other.mobileUrl;

  @override
  int get hashCode => Object.hash(desktopUrl, mobileUrl);

  @override
  String toString() =>
      'ContentUrls(desktopUrl: $desktopUrl, mobileUrl: $mobileUrl)';
}
