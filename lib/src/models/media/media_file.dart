import 'package:meta/meta.dart';

/// Metadata for a specific Wikimedia media file.
///
/// Returned by [MediaClient.getFile]. Primarily useful for querying
/// Wikimedia Commons files.
@immutable
class MediaFile {
  /// Creates a [MediaFile].
  const MediaFile({
    required this.title,
    required this.sourceUrl,
    this.description,
    this.mimeType,
    this.width,
    this.height,
    this.fileSizeBytes,
  });

  /// File title, e.g. `'File:Earth_Western_Hemisphere.jpg'`.
  final String title;

  /// Direct URL to the full-resolution source file.
  final String sourceUrl;

  /// Description of the file, if available.
  final String? description;

  /// MIME type of the file, e.g. `'image/jpeg'`.
  final String? mimeType;

  /// Width of the image in pixels, if applicable.
  final int? width;

  /// Height of the image in pixels, if applicable.
  final int? height;

  /// Size of the file in bytes, if available.
  final int? fileSizeBytes;

  /// Deserialises a [MediaFile] from a JSON map.
  factory MediaFile.fromJson(Map<String, dynamic> json) {
    final original =
        (json['originalimage'] ?? json['original']) as Map<String, dynamic>?;
    var sourceUrl = (original?['source'] ?? json['source'] ?? '') as String;
    if (sourceUrl.startsWith('//')) {
      sourceUrl = 'https:$sourceUrl';
    }
    return MediaFile(
      title: json['title'] as String,
      sourceUrl: sourceUrl,
      description: json['description'] as String?,
      mimeType: json['type'] as String?,
      width: original?['width'] as int?,
      height: original?['height'] as int?,
      fileSizeBytes: json['file_size'] as int?,
    );
  }

  /// Returns a copy of this [MediaFile] with the given fields replaced.
  MediaFile copyWith({
    String? title,
    String? sourceUrl,
    String? description,
    String? mimeType,
    int? width,
    int? height,
    int? fileSizeBytes,
  }) =>
      MediaFile(
        title: title ?? this.title,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        description: description ?? this.description,
        mimeType: mimeType ?? this.mimeType,
        width: width ?? this.width,
        height: height ?? this.height,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFile &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          sourceUrl == other.sourceUrl &&
          description == other.description &&
          mimeType == other.mimeType &&
          width == other.width &&
          height == other.height &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode => Object.hash(
        title,
        sourceUrl,
        description,
        mimeType,
        width,
        height,
        fileSizeBytes,
      );

  @override
  String toString() => 'MediaFile(title: $title, mimeType: $mimeType, '
      'width: $width, height: $height)';
}
