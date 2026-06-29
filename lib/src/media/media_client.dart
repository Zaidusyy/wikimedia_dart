import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/media/media_file.dart';
import '../models/media/media_item.dart';
import '../utils/url_builder.dart';

/// Implements the `wiki.media.*` namespace.
///
/// Access this via [WikiClient.media] — do not instantiate directly.
class MediaClient with ServiceBase {
  /// Creates a [MediaClient].
  MediaClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Returns all media items embedded in the article with [title].
  ///
  /// [language] overrides the client's default language for this
  /// request only.
  Future<List<MediaItem>> listForPage(
    String title, {
    String? language,
  }) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageMediaList}/${Uri.encodeComponent(title)}',
      languageOverride: language,
    );
    return get(
      uri,
      (json) => (json['items'] as List<dynamic>)
          .where((e) => (e as Map<String, dynamic>)['title'] != null)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns metadata for a specific media file by [fileTitle].
  ///
  /// [fileTitle] should include the `File:` prefix, e.g.
  /// `'File:Earth_Western_Hemisphere.jpg'`.
  ///
  /// Primarily useful for querying files hosted on Wikimedia Commons.
  Future<MediaFile> getFile(String fileTitle) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageSummary}/${Uri.encodeComponent(fileTitle)}',
    );
    return get(uri, MediaFile.fromJson);
  }
}
