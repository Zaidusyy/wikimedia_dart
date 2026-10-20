/// The package version, kept in step with `pubspec.yaml`.
///
/// Only used to build [defaultUserAgent]. A test asserts this matches the
/// `version:` field in `pubspec.yaml`, so a release bump can't silently leave
/// the User-Agent behind.
const String packageVersion = '0.1.1';

/// The `User-Agent` sent when the caller doesn't supply one.
///
/// Wikimedia's User-Agent policy asks every client to identify itself
/// accurately; production apps should pass their own instead. See
/// https://meta.wikimedia.org/wiki/User-Agent_policy
const String defaultUserAgent =
    'WikimediaDart/$packageVersion (https://github.com/Zaidusyy/wikimedia_dart)';
