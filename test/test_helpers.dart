import 'dart:convert';
import 'dart:io';

/// Reads the fixture file at [path] relative to `test/fixtures/`.
///
/// Fixture files contain verbatim Wikimedia REST API responses captured
/// with `curl`. They are the ground truth for model parsing tests.
String fixture(String path) => File('test/fixtures/$path').readAsStringSync();

/// Reads and JSON-decodes the fixture file at [path].
Map<String, dynamic> fixtureMap(String path) =>
    jsonDecode(fixture(path)) as Map<String, dynamic>;
