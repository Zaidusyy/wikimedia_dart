import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() {
  group('MediaFile JSON Parsing', () {
    test('parses with originalimage key (PageSummary format)', () {
      final json = {
        'title': 'File:Earth.jpg',
        'type': 'image',
        'file_size': 12345,
        'description': 'Earth from space',
        'originalimage': {
          'source': '//upload.wikimedia.org/wikipedia/commons/earth.jpg',
          'width': 1024,
          'height': 768,
        }
      };

      final file = MediaFile.fromJson(json);

      expect(file.title, 'File:Earth.jpg');
      expect(file.mimeType, 'image');
      expect(file.fileSizeBytes, 12345);
      expect(file.description, 'Earth from space');
      expect(file.sourceUrl,
          'https://upload.wikimedia.org/wikipedia/commons/earth.jpg');
      expect(file.width, 1024);
      expect(file.height, 768);
    });

    test('parses with legacy original key', () {
      final json = {
        'title': 'File:Earth.jpg',
        'type': 'image',
        'file_size': 12345,
        'original': {
          'source': 'https://upload.wikimedia.org/wikipedia/commons/earth.jpg',
          'width': 1024,
          'height': 768,
        }
      };

      final file = MediaFile.fromJson(json);

      expect(file.sourceUrl,
          'https://upload.wikimedia.org/wikipedia/commons/earth.jpg');
      expect(file.width, 1024);
      expect(file.height, 768);
    });

    test('normalizes protocol-relative sourceUrl starting with //', () {
      final json = {
        'title': 'File:Earth.jpg',
        'source': '//upload.wikimedia.org/earth.jpg',
      };

      final file = MediaFile.fromJson(json);
      expect(file.sourceUrl, 'https://upload.wikimedia.org/earth.jpg');
    });

    test('copyWith and equality', () {
      const file = MediaFile(
        title: 'File:Earth.jpg',
        sourceUrl: 'https://example.com/earth.jpg',
      );

      final copy = file.copyWith(title: 'File:New.jpg');
      expect(copy.title, 'File:New.jpg');
      expect(copy.sourceUrl, 'https://example.com/earth.jpg');

      expect(
          file,
          equals(const MediaFile(
            title: 'File:Earth.jpg',
            sourceUrl: 'https://example.com/earth.jpg',
          )));
    });
  });

  group('MediaItem JSON Parsing', () {
    test('parses with original source URL', () {
      final json = {
        'title': 'File:Earth.jpg',
        'type': 'image',
        'original': {
          'source': 'https://upload.wikimedia.org/wikipedia/commons/earth.jpg',
        },
        'caption': 'The blue marble',
      };

      final item = MediaItem.fromJson(json);

      expect(item.title, 'File:Earth.jpg');
      expect(item.type, 'image');
      expect(item.srcUrl,
          'https://upload.wikimedia.org/wikipedia/commons/earth.jpg');
      expect(item.caption, 'The blue marble');
    });

    test('fallback to first srcset entry if original is missing', () {
      final json = {
        'title': 'File:Earth.jpg',
        'type': 'image',
        'srcset': [
          {
            'src':
                '//upload.wikimedia.org/wikipedia/commons/thumb/earth_200px.jpg',
            'scale': '1x',
          },
          {
            'src':
                '//upload.wikimedia.org/wikipedia/commons/thumb/earth_400px.jpg',
            'scale': '2x',
          }
        ],
        'caption': {
          'html': '<i>The blue marble</i>',
          'text': 'The blue marble plain text',
        }
      };

      final item = MediaItem.fromJson(json);

      expect(item.srcUrl,
          'https://upload.wikimedia.org/wikipedia/commons/thumb/earth_200px.jpg');
      expect(item.caption, 'The blue marble plain text');
    });

    test('normalizes protocol-relative URL inside srcset', () {
      final json = {
        'title': 'File:Earth.jpg',
        'type': 'image',
        'srcset': [
          {'src': '//upload.wikimedia.org/earth.jpg'}
        ]
      };

      final item = MediaItem.fromJson(json);
      expect(item.srcUrl, 'https://upload.wikimedia.org/earth.jpg');
    });

    test('copyWith and equality', () {
      const item = MediaItem(
        title: 'File:Earth.jpg',
        type: 'image',
      );

      final copy = item.copyWith(caption: 'New caption');
      expect(copy.caption, 'New caption');
      expect(copy.title, 'File:Earth.jpg');

      expect(
          item,
          equals(const MediaItem(
            title: 'File:Earth.jpg',
            type: 'image',
          )));
    });
  });
}
