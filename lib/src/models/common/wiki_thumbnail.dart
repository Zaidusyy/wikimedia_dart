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

  /// Width of the thumbnail in pixels.
  final int width;

  /// Height of the thumbnail in pixels.
  final int height;

  /// Deserialises a [WikiThumbnail] from a JSON map.
  factory WikiThumbnail.fromJson(Map<String, dynamic> json) {
    var sourceUrl = (json['source'] ?? json['url'] ?? '') as String;
    if (sourceUrl.startsWith('//')) {
      sourceUrl = 'https:$sourceUrl';
    }
    return WikiThumbnail(
      source: sourceUrl,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

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
