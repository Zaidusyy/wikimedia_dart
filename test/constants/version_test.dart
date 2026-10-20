import 'dart:io';

import 'package:test/test.dart';
import 'package:wikimedia_dart/src/constants/version.dart';

void main() {
  group('packageVersion', () {
    test('matches the version in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match =
          RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(pubspec);

      expect(match, isNotNull,
          reason: 'no version: line found in pubspec.yaml');
      expect(
        match!.group(1),
        packageVersion,
        reason: 'pubspec.yaml and lib/src/constants/version.dart disagree. '
            'Bump both when releasing, or the User-Agent will report a stale '
            'version to Wikimedia.',
      );
    });
  });

  group('defaultUserAgent', () {
    test('carries the current version', () {
      expect(defaultUserAgent, contains('WikimediaDart/$packageVersion'));
    });

    test('carries a contact URL, as the User-Agent policy requires', () {
      expect(defaultUserAgent, contains('https://github.com/'));
    });
  });
}
