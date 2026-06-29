import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() {
  group('SearchResponse', () {
    test('fromJson parses pages list', () {
      final json = <String, dynamic>{
        'pages': [
          {
            'title': 'Earth',
            'id': 9228,
            'description': 'Third planet from the Sun',
            'excerpt': 'Earth is the third planet...',
          },
          {
            'title': 'Moon',
            'id': 15215,
          },
        ],
      };
      final response = SearchResponse.fromJson(json);
      expect(response.pages.length, 2);
      expect(response.pages.first.title, 'Earth');
      expect(response.pages.first.pageId, 9228);
      expect(response.pages.first.description, 'Third planet from the Sun');
      expect(response.nextCursor, isNull);
    });

    test('fromJson parses nextCursor when present', () {
      final json = <String, dynamic>{
        'pages': <dynamic>[],
        'next': 'abc123',
      };
      final response = SearchResponse.fromJson(json);
      expect(response.nextCursor, 'abc123');
    });

    test('fromJson handles empty pages list', () {
      final json = <String, dynamic>{'pages': <dynamic>[]};
      final response = SearchResponse.fromJson(json);
      expect(response.pages, isEmpty);
    });
  });

  group('SearchResultItem', () {
    test('fromJson parses required fields', () {
      final json = <String, dynamic>{
        'title': 'Earth',
        'id': 9228,
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.title, 'Earth');
      expect(item.pageId, 9228);
      expect(item.description, isNull);
      expect(item.excerpt, isNull);
      expect(item.thumbnail, isNull);
    });

    test('fromJson parses optional fields', () {
      final json = <String, dynamic>{
        'title': 'Earth',
        'id': 9228,
        'description': 'Third planet',
        'excerpt': 'Earth is...',
        'thumbnail': {
          'source': 'https://example.com/earth.jpg',
          'width': 100,
          'height': 80,
        },
      };
      final item = SearchResultItem.fromJson(json);
      expect(item.description, 'Third planet');
      expect(item.excerpt, 'Earth is...');
      expect(item.thumbnail, isNotNull);
      expect(item.thumbnail!.width, 100);
    });

    test('equality and hashCode', () {
      final a = SearchResultItem.fromJson({
        'title': 'Earth',
        'id': 9228,
      });
      final b = SearchResultItem.fromJson({
        'title': 'Earth',
        'id': 9228,
      });
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
