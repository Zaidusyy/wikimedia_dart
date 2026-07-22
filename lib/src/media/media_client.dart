import 'package:http/http.dart' as http;

import '../client/service_base.dart';
import '../client/wiki_config.dart';
import '../constants/endpoints.dart';
import '../models/media/media_file.dart';
import '../models/media/media_item.dart';
import '../utils/url_builder.dart';

/// Media endpoints, reached through `wiki.media`.
class MediaClient with ServiceBase {
  /// Built by [WikiClient], which owns and shares [config] and [httpClient].
  MediaClient(this.config, this.httpClient, this._closedRef);

  @override
  final WikiConfig config;

  @override
  final http.Client httpClient;

  final bool Function() _closedRef;

  @override
  bool get isClosed => _closedRef();

  /// Lists the media embedded in the article [title].
  ///
  /// Pass [language] to hit a different wiki edition just for this call.
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

  /// Metadata for a single file, e.g. one hosted on Commons.
  ///
  /// [fileTitle] should keep the `File:` prefix, like
  /// `'File:Earth_Western_Hemisphere.jpg'`.
  Future<MediaFile> getFile(String fileTitle) async {
    assertOpen();
    final uri = UrlBuilder.build(
      config: config,
      path: '${Endpoints.pageSummary}/${Uri.encodeComponent(fileTitle)}',
    );
    return get(uri, MediaFile.fromJson);
  }
}
