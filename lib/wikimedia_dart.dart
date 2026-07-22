/// A type-safe Dart client for the Wikimedia REST APIs.
///
/// Import this one file to get everything public:
///
/// ```dart
/// import 'package:wikimedia_dart/wikimedia_dart.dart';
/// ```
library wikimedia_dart;

export 'src/client/retry_policy.dart';
export 'src/client/wiki_client.dart';
export 'src/errors/wiki_exception.dart';
export 'src/media/media_client.dart';
export 'src/models/common/content_urls.dart';
export 'src/models/common/wiki_project.dart';
export 'src/models/common/wiki_thumbnail.dart';
export 'src/models/media/media_file.dart';
export 'src/models/media/media_item.dart';
export 'src/models/pages/page_summary.dart';
export 'src/models/search/search_response.dart';
export 'src/models/search/search_result_item.dart';
export 'src/pages/pages_client.dart';
export 'src/search/search_client.dart';
