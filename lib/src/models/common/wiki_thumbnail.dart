import 'package:meta/meta.dart';

/// A thumbnail image associated with a Wikimedia article or media file.
@immutable
class WikiThumbnail {
  /// Creates a [WikiThumbnail].
  const WikiThumbnail({
    required this.source,
    required this.width,
    required this.height,
  });

  /// Full URL to the thumbnail image.
  final String source;

  /// Width of the thumbnail in pixels, or 0 if the API didn't say.
  final int width;

  /// Height of the thumbnail in pixels, or 0 if the API didn't say.
  final int height;

  /// Parses a [WikiThumbnail] from the API's JSON.
  ///
  /// The search endpoints may send null dimensions; those become 0 rather
  /// than failing the whole response.
  factory WikiThumbnail.fromJson(Map<String, dynamic> json) {
    var sourceUrl = (json['source'] ?? json['url'] ?? '') as String;
    if (sourceUrl.startsWith('//')) {
      sourceUrl = 'https:$sourceUrl';
    }
    return WikiThumbnail(
      source: sourceUrl,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this thumbnail back to the API's JSON shape.
  ///
  /// Round-trips through [WikiThumbnail.fromJson].
  Map<String, dynamic> toJson() => {
        'source': source,
        'width': width,
        'height': height,
      };

  /// Returns a copy of this thumbnail with the given fields replaced.
  WikiThumbnail copyWith({
    String? source,
    int? width,
    int? height,
  }) =>
      WikiThumbnail(
        source: source ?? this.source,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WikiThumbnail &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(source, width, height);

  @override
  String toString() =>
      'WikiThumbnail(source: $source, width: $width, height: $height)';
}
