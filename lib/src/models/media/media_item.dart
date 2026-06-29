import 'package:meta/meta.dart';

/// A media item embedded in a Wikimedia article.
///
/// Returned by [MediaClient.listForPage].
@immutable
class MediaItem {
  /// Creates a [MediaItem].
  const MediaItem({
    required this.title,
    required this.type,
    this.srcUrl,
    this.caption,
  });

  /// File title, e.g. `'File:Earth_Western_Hemisphere.jpg'`.
  final String title;

  /// Media type: `'image'`, `'video'`, or `'audio'`.
  final String type;

  /// Direct URL to the media file, if available.
  final String? srcUrl;

  /// Caption text for this media item, if available.
  final String? caption;

  /// Deserialises a [MediaItem] from a JSON map.
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    // The media-list endpoint nests items; extract srcUrl from 'original'
    // or the first entry in 'srcset' when available.
    final original = json['original'] as Map<String, dynamic>?;
    var srcUrl = original?['source'] as String?;

    if (srcUrl == null) {
      final srcset = json['srcset'] as List<dynamic>?;
      if (srcset != null && srcset.isNotEmpty) {
        final first = srcset.first as Map<String, dynamic>;
        srcUrl = first['src'] as String?;
      }
    }

    if (srcUrl != null && srcUrl.startsWith('//')) {
      srcUrl = 'https:$srcUrl';
    }

    String? captionText;
    final captionJson = json['caption'];
    if (captionJson is String) {
      captionText = captionJson;
    } else if (captionJson is Map) {
      captionText = captionJson['text'] as String?;
    }

    return MediaItem(
      title: json['title'] as String,
      type: json['type'] as String,
      srcUrl: srcUrl,
      caption: captionText,
    );
  }

  /// Returns a copy of this [MediaItem] with the given fields replaced.
  MediaItem copyWith({
    String? title,
    String? type,
    String? srcUrl,
    String? caption,
  }) =>
      MediaItem(
        title: title ?? this.title,
        type: type ?? this.type,
        srcUrl: srcUrl ?? this.srcUrl,
        caption: caption ?? this.caption,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          type == other.type &&
          srcUrl == other.srcUrl &&
          caption == other.caption;

  @override
  int get hashCode => Object.hash(title, type, srcUrl, caption);

  @override
  String toString() => 'MediaItem(title: $title, type: $type)';
}
