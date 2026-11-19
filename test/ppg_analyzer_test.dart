import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellumi/core/utils/health_classifier.dart';
import 'package:wellumi/core/utils/ppg/ppg_analyzer.dart';
import 'package:wellumi/core/utils/ppg/ppg_models.dart';
import 'package:wellumi/core/utils/ppg/vitals_estimator.dart';
import 'package:wellumi/data/models/calibration_point.dart';

/// Simulates what the camera sees through a fingertip: a bright red frame whose
/// brightness dips with every heartbeat, with frame-time jitter, sensor noise,
/// slow drift and respiratory sinus arrhythmia.
List<PpgSample> syntheticScan({
  double bpm = 72,
  double breathsPerMin = 15,
  double seconds = 48,
  double fps = 30,
  double noise = 0.25,
  bool covered = true,
  int seed = 42,
}) {
  final rnd = math.Random(seed);
  // Beat onset times with breathing-modulated intervals.
  final beats = <double>[0];
  while (beats.last < seconds + 2) {
    final t = beats.last;
    final ibi = 60 / bpm * (1 + 0.05 * math.sin(2 * math.pi * breathsPerMin / 60 * t));
    beats.add(t + ibi);
  }
  double shape(double p) =>
      math.exp(-math.pow((p - 0.18) / 0.075, 2)) + 0.38 * math.exp(-math.pow((p - 0.47) / 0.09, 2));

  final samples = <PpgSample>[];
  var t = 0.0;
  var k = 0;
  while (t < seconds) {
    while (k < beats.length - 2 && beats[k + 1] <= t) {
      k++;
    }
    final p = (t - beats[k]) / (beats[k + 1] - beats[k]);
    final pulse = shape(p);
    final drift = 4 * math.sin(2 * math.pi * 0.03 * t);
    double n() => (rnd.nextDouble() - 0.5) * 2 * noise;
    samples.add(
      PpgSample(
        t: t,
        red: covered ? 205 - 3.0 * pulse + drift + n() : 90 + n(),
        green: covered ? 40 - 0.4 * pulse + n() : 85 + n(),
        blue: covered ? 30 - 0.35 * pulse + n() : 80 + n(),
        covered: covered,
      ),
    );
    t += 1 / fps + (rnd.nextDouble() - 0.5) * 0.008; // frame jitter
  }
  return samples;
}

void main() {
  group('PpgAnalyzer', () {
    test('recovers heart rate from a clean fingertip signal', () {
      final r = PpgAnalyzer.analyze(syntheticScan(bpm: 72));
      expect(r.success, isTrue, reason: 'failure: ${r.failure}');
      expect(r.heartRate, closeTo(72, 3));
      expect(r.quality, greaterThanOrEqualTo(60));
      expect(r.beatCount, greaterThan(30));
    });

    for (final bpm in [52.0, 88.0, 115.0]) {
      test('tracks $bpm bpm', () {
        final r = PpgAnalyzer.analyze(syntheticScan(bpm: bpm, seed: bpm.toInt()));
        expect(r.success, isTrue, reason: 'failure: ${r.failure}');
        expect(r.heartRate, closeTo(bpm, 4));
      });
    }

    test('estimates breathing rate from beat-to-beat modulation', () {
      final r = PpgAnalyzer.analyze(syntheticScan(bpm: 70, breathsPerMin: 15));
      expect(r.breathingRate, isNotNull);
      expect(r.breathingRate!, closeTo(15, 3));
    });

    test('reports HRV from respiratory variation', () {
      final r = PpgAnalyzer.analyze(syntheticScan());
      expect(r.rmssdMs, greaterThan(5));
      expect(r.sdnnMs, greaterThan(5));
    });

    test('fails when no finger covers the camera', () {
      final r = PpgAnalyzer.analyze(syntheticScan(covered: false));
      expect(r.success, isFalse);
      expect(r.failure, ScanFailureReason.fingerNotDetected);
    });

    for (final seed in [1, 2, 3, 7, 11]) {
      test('fails on pure noise instead of inventing a heart rate (seed $seed)', () {
        final rnd = math.Random(seed);
        final samples = [
          for (var i = 0; i < 48 * 30; i++)
            PpgSample(t: i / 30, red: 200 + rnd.nextDouble() * 3, green: 40, blue: 30, covered: true),
        ];
        expect(PpgAnalyzer.analyze(samples).success, isFalse);
      });
    }

    test('still reads a noisy but real pulse', () {
      final r = PpgAnalyzer.analyze(syntheticScan(bpm: 76, noise: 1.5, seed: 5));
      expect(r.success, isTrue, reason: 'failure: ${r.failure}');
      expect(r.heartRate, closeTo(76, 4));
    });

    test('fails when the scan is too short', () {
      final r = PpgAnalyzer.analyze(syntheticScan(seconds: 12));
      expect(r.failure, ScanFailureReason.tooShort);
    });

    test('live estimate converges during the scan', () {
      final all = syntheticScan(bpm: 80);
      final last10 = all.where((s) => s.t > all.last.t - 10).toList();
      final live = PpgAnalyzer.quickEstimate(last10);
      expect(live.heartRate, isNotNull);
      expect(live.heartRate!, closeTo(80, 5));
    });

    test('display waveform is normalised', () {
      final w = PpgAnalyzer.displayWaveform(syntheticScan(seconds: 8));
      expect(w, isNotEmpty);
      expect(w.every((v) => v >= -1.0001 && v <= 1.0001), isTrue);
    });
  });

  group('VitalsEstimator', () {
    test('BP estimate stays in a plausible range', () {
      final r = PpgAnalyzer.analyze(syntheticScan());
      final bp = VitalsEstimator.estimateBp(features: r.features, heartRate: r.heartRate, profile: null);
      expect(bp.systolic, inInclusiveRange(85, 190));
      expect(bp.diastolic, inInclusiveRange(50, 120));
      expect(bp.systolic - bp.diastolic, inInclusiveRange(25, 75));
    });

    test('calibration shifts estimates by the mean cuff offset', () {
      final points = [
        CalibrationPoint(
          id: 'a',
          timestamp: DateTime(2026, 1, 1),
          scanReadingId: 's1',
          cuffSystolic: 130,
          cuffDiastolic: 85,
          estimatedSystolic: 120,
          estimatedDiastolic: 80,
        ),
        CalibrationPoint(
          id: 'b',
          timestamp: DateTime(2026, 1, 2),
          scanReadingId: 's2',
          cuffSystolic: 128,
          cuffDiastolic: 84,
          estimatedSystolic: 120,
          estimatedDiastolic: 80,
        ),
      ];
      final out = VitalsEstimator.calibrate(const BpEstimate(118, 76), points);
      expect(out.systolic, 127); // +9
      expect(out.diastolic, 81); // 76 + 4.5 = 80.5, rounds half up
    });

    test('stress score falls as HRV rises', () {
      final low = VitalsEstimator.stressScore(rmssdMs: 80, heartRate: 62);
      final high = VitalsEstimator.stressScore(rmssdMs: 12, heartRate: 95);
      expect(low, lessThan(40));
      expect(high, greaterThan(70));
    });
  });

  group('BpCategory', () {
    test('follows AHA thresholds', () {
      expect(BpCategory.classify(115, 75), BpCategory.normal);
      expect(BpCategory.classify(125, 75), BpCategory.elevated);
      expect(BpCategory.classify(132, 78), BpCategory.stage1);
      expect(BpCategory.classify(118, 92), BpCategory.stage2);
      expect(BpCategory.classify(185, 100), BpCategory.crisis);
    });
  });
}
