import 'package:flutter_test/flutter_test.dart';
import 'package:wellumi/core/utils/version_utils.dart';

void main() {
  group('VersionUtils.compare', () {
    test('orders numeric parts, not strings', () {
      expect(VersionUtils.isOlder('1.9.0', '1.10.0'), isTrue);
      expect(VersionUtils.isOlder('1.10.0', '1.9.0'), isFalse);
    });

    test('ignores build numbers and a v prefix', () {
      expect(VersionUtils.compare('1.2.0+7', '1.2.0+9'), 0);
      expect(VersionUtils.compare('v2.0', '2.0.0'), 0);
    });

    test('treats missing parts as zero', () {
      expect(VersionUtils.compare('1.2', '1.2.0'), 0);
      expect(VersionUtils.isOlder('1.2', '1.2.1'), isTrue);
    });
  });

  group('UpdatePolicy.decide', () {
    test('no update when nothing newer and no minimum', () {
      expect(UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: false), UpdateUrgency.none);
    });

    test('optional when a newer version exists', () {
      expect(UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: true), UpdateUrgency.optional);
    });

    test('required when below the hosted minimum version', () {
      expect(
        UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: true, minSupportedVersion: '1.1.0'),
        UpdateUrgency.required,
      );
    });

    test('not required when at or above the minimum', () {
      expect(
        UpdatePolicy.decide(currentVersion: '1.1.0', newerAvailable: true, minSupportedVersion: '1.1.0'),
        UpdateUrgency.optional,
      );
    });

    test('required for high Play priority updates', () {
      expect(
        UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: true, playPriority: 4),
        UpdateUrgency.required,
      );
      expect(
        UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: true, playPriority: 3),
        UpdateUrgency.optional,
      );
    });

    test('high priority without an available update does nothing', () {
      expect(UpdatePolicy.decide(currentVersion: '1.0.0', newerAvailable: false, playPriority: 5), UpdateUrgency.none);
    });
  });
}
