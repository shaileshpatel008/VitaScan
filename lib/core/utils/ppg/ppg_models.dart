/// One camera frame reduced to its average colour.
class PpgSample {
  const PpgSample({required this.t, required this.red, required this.green, required this.blue, required this.covered});

  /// Seconds since the scan started.
  final double t;
  final double red;
  final double green;
  final double blue;

  /// Whether a fingertip was covering the lens in this frame.
  final bool covered;
}

enum ScanFailureReason { fingerNotDetected, fingerMoved, noPulse, weakSignal, tooShort, lowFrameRate }

/// Pulse-wave shape descriptors from the averaged beat.
class PpgFeatures {
  const PpgFeatures({
    required this.riseRatio,
    required this.reflectionIndex,
    required this.halfWidthRatio,
    required this.perfusionIndex,
  });

  /// Foot-to-peak time as a share of the beat interval.
  final double riseRatio;

  /// Height of the reflected (diastolic) wave relative to the systolic peak.
  final double reflectionIndex;

  /// Pulse width at half height as a share of the beat interval.
  final double halfWidthRatio;

  /// Pulsatile / static light ratio in percent.
  final double perfusionIndex;

  static const neutral = PpgFeatures(riseRatio: 0.2, reflectionIndex: 0.5, halfWidthRatio: 0.35, perfusionIndex: 1.0);
}

class PpgAnalysisResult {
  const PpgAnalysisResult._({
    required this.success,
    this.failure,
    this.heartRate = 0,
    this.rmssdMs = 0,
    this.sdnnMs = 0,
    this.breathingRate,
    this.spo2,
    this.quality = 0,
    this.beatCount = 0,
    this.features = PpgFeatures.neutral,
  });

  factory PpgAnalysisResult.failed(ScanFailureReason reason, {int quality = 0}) =>
      PpgAnalysisResult._(success: false, failure: reason, quality: quality);

  factory PpgAnalysisResult.ok({
    required double heartRate,
    required double rmssdMs,
    required double sdnnMs,
    required double? breathingRate,
    required double? spo2,
    required int quality,
    required int beatCount,
    required PpgFeatures features,
  }) => PpgAnalysisResult._(
    success: true,
    heartRate: heartRate,
    rmssdMs: rmssdMs,
    sdnnMs: sdnnMs,
    breathingRate: breathingRate,
    spo2: spo2,
    quality: quality,
    beatCount: beatCount,
    features: features,
  );

  final bool success;
  final ScanFailureReason? failure;
  final double heartRate;
  final double rmssdMs;
  final double sdnnMs;
  final double? breathingRate;
  final double? spo2;
  final int quality;
  final int beatCount;
  final PpgFeatures features;
}

class LiveEstimate {
  const LiveEstimate({required this.heartRate, required this.quality});
  final double? heartRate;

  /// 0..100
  final int quality;
}
