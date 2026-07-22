import 'package:test/test.dart';
import 'package:wikimedia_dart/wikimedia_dart.dart';

void main() {
  group('RetryPolicy', () {
    test('default policy performs retries', () {
      const policy = RetryPolicy();
      expect(policy.maxRetries, 3);
      expect(policy.isEnabled, isTrue);
      expect(policy.initialBackoff, const Duration(milliseconds: 500));
      expect(policy.maxBackoff, const Duration(seconds: 30));
      expect(policy.backoffMultiplier, 2.0);
    });

    test('none() disables retries', () {
      const policy = RetryPolicy.none();
      expect(policy.maxRetries, 0);
      expect(policy.isEnabled, isFalse);
    });

    test('backoffFor grows exponentially from initialBackoff', () {
      const policy = RetryPolicy(); // 500ms initial, 2.0 multiplier (defaults)
      expect(policy.backoffFor(0), const Duration(milliseconds: 500));
      expect(policy.backoffFor(1), const Duration(seconds: 1));
      expect(policy.backoffFor(2), const Duration(seconds: 2));
      expect(policy.backoffFor(3), const Duration(seconds: 4));
    });

    test('backoffFor is capped at maxBackoff', () {
      const policy = RetryPolicy(
        initialBackoff: Duration(seconds: 10),
      ); // maxBackoff 30s, multiplier 2.0 (defaults)
      expect(policy.backoffFor(0), const Duration(seconds: 10));
      expect(policy.backoffFor(1), const Duration(seconds: 20));
      // 40s would exceed the 30s cap.
      expect(policy.backoffFor(2), const Duration(seconds: 30));
      expect(policy.backoffFor(10), const Duration(seconds: 30));
    });

    test('backoffFor honors a server Retry-After over the schedule', () {
      const policy = RetryPolicy();
      expect(
        policy.backoffFor(0, retryAfter: const Duration(seconds: 12)),
        const Duration(seconds: 12),
      );
    });

    test('backoffFor caps Retry-After at maxBackoff', () {
      const policy = RetryPolicy(); // maxBackoff 30s (default)
      expect(
        policy.backoffFor(0, retryAfter: const Duration(seconds: 120)),
        const Duration(seconds: 30),
      );
    });

    test('custom multiplier is applied', () {
      const policy = RetryPolicy(
        initialBackoff: Duration(milliseconds: 100),
        backoffMultiplier: 3.0,
      );
      expect(policy.backoffFor(0), const Duration(milliseconds: 100));
      expect(policy.backoffFor(1), const Duration(milliseconds: 300));
      expect(policy.backoffFor(2), const Duration(milliseconds: 900));
    });
  });
}
