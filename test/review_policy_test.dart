import 'package:flutter_test/flutter_test.dart';
import 'package:wellumi/core/utils/review_policy.dart';

void main() {
  final now = DateTime(2026, 11, 27);

  group('ReviewPolicy.isGoodResult', () {
    test('needs a clear signal and a calm result', () {
      expect(ReviewPolicy.isGoodResult(signalQuality: 90, needsAttention: false), isTrue);
      expect(ReviewPolicy.isGoodResult(signalQuality: 60, needsAttention: false), isFalse);
      expect(ReviewPolicy.isGoodResult(signalQuality: null, needsAttention: false), isFalse);
      expect(ReviewPolicy.isGoodResult(signalQuality: 95, needsAttention: true), isFalse);
    });
  });

  group('ReviewPolicy.shouldAsk', () {
    test('not before the 2nd good scan', () {
      expect(ReviewPolicy.shouldAsk(goodScans: 1, timesAsked: 0, lastAskedAt: null, now: now), isFalse);
      expect(ReviewPolicy.shouldAsk(goodScans: 2, timesAsked: 0, lastAskedAt: null, now: now), isTrue);
    });

    test('waits 90 days between prompts', () {
      final recent = now.subtract(const Duration(days: 30));
      final old = now.subtract(const Duration(days: 91));
      expect(ReviewPolicy.shouldAsk(goodScans: 9, timesAsked: 1, lastAskedAt: recent, now: now), isFalse);
      expect(ReviewPolicy.shouldAsk(goodScans: 9, timesAsked: 1, lastAskedAt: old, now: now), isTrue);
    });

    test('stops after 3 prompts', () {
      final old = now.subtract(const Duration(days: 365));
      expect(ReviewPolicy.shouldAsk(goodScans: 50, timesAsked: 3, lastAskedAt: old, now: now), isFalse);
    });
  });
}
