import 'dart:math' as math;

import '../../constants/app_constants.dart';
import 'biquad_filter.dart';
import 'peak_detector.dart';
import 'ppg_models.dart';
import 'signal_math.dart';

/// Turns raw per-frame colour averages into heart rate, HRV, breathing rate,
/// an SpO2 estimate and pulse-shape features. Pure Dart: safe to run inside
/// `Isolate.run`.
class PpgAnalyzer {
  PpgAnalyzer._();

  static const double fs = AppConstants.analysisFs;
  static const double _hrLow = 0.6; // 36 bpm
  static const double _hrHigh = 3.3; // 198 bpm

  // ------------------------------------------------------------------ full scan

  static PpgAnalysisResult analyze(List<PpgSample> all, {double warmup = AppConstants.warmupSeconds}) {
    if (all.length < 2) return PpgAnalysisResult.failed(ScanFailureReason.fingerNotDetected);
    final t0 = all.first.t + warmup;
    final samples = all.where((s) => s.t >= t0).toList();
    if (samples.length < 2) return PpgAnalysisResult.failed(ScanFailureReason.tooShort);

    final duration = samples.last.t - samples.first.t;
    if (duration < 20) return PpgAnalysisResult.failed(ScanFailureReason.tooShort);

    final coverage = samples.where((s) => s.covered).length / samples.length;
    if (coverage < 0.2) return PpgAnalysisResult.failed(ScanFailureReason.fingerNotDetected);
    if (coverage < 0.7) return PpgAnalysisResult.failed(ScanFailureReason.fingerMoved);

    if (samples.length / duration < AppConstants.minEffectiveFps) {
      return PpgAnalysisResult.failed(ScanFailureReason.lowFrameRate);
    }

    final times = samples.map((s) => s.t).toList();
    final red = SignalMath.resampleUniform(times, samples.map((s) => s.red).toList(), fs);
    final blue = SignalMath.resampleUniform(times, samples.map((s) => s.blue).toList(), fs);

    final redBand = BandPassFilter.filtfilt(red, fs, _hrLow, _hrHigh);
    final pulse = redBand.map((v) => -v).toList(); // more blood = less light

    final perfusion = _perfusionIndex(pulse, red);
    final peaks = PeakDetector.detect(pulse, fs);
    final beats = _beats(peaks);
    final valid = beats.where((b) => b.valid).toList();

    if (valid.length < AppConstants.minValidBeats || valid.length / beats.length < AppConstants.minValidBeatRatio) {
      return PpgAnalysisResult.failed(
        perfusion < AppConstants.minPerfusionIndex ? ScanFailureReason.weakSignal : ScanFailureReason.noPulse,
      );
    }

    final ibis = valid.map((b) => b.ibi).toList();
    final heartRate = 60 / SignalMath.median(ibis);
    final quality = _quality(coverage: coverage, validRatio: valid.length / beats.length, pulse: pulse, ibis: ibis);
    if (quality < AppConstants.minSignalQuality || perfusion < AppConstants.minPerfusionIndex) {
      return PpgAnalysisResult.failed(ScanFailureReason.weakSignal, quality: quality);
    }

    final hrv = _hrv(beats);
    final morphology = BandPassFilter.filtfilt(red, fs, 0.5, 8).map((v) => -v).toList();

    return PpgAnalysisResult.ok(
      heartRate: heartRate,
      rmssdMs: hrv.rmssd,
      sdnnMs: hrv.sdnn,
      breathingRate: _breathingRate(valid, pulse),
      spo2: _spo2(red, redBand, blue),
      quality: quality,
      beatCount: valid.length,
      features: _features(morphology, peaks, perfusion),
    );
  }

  // ------------------------------------------------------------------ live

  /// Cheap estimate over the most recent window, used while scanning.
  static LiveEstimate quickEstimate(List<PpgSample> recent) {
    if (recent.length < 30) return const LiveEstimate(heartRate: null, quality: 0);
    final times = recent.map((s) => s.t).toList();
    final red = SignalMath.resampleUniform(times, recent.map((s) => s.red).toList(), fs);
    final pulse = BandPassFilter.filtfilt(red, fs, _hrLow, _hrHigh).map((v) => -v).toList();
    final beats = _beats(PeakDetector.detect(pulse, fs));
    final valid = beats.where((b) => b.valid).toList();
    if (valid.length < 4) return const LiveEstimate(heartRate: null, quality: 20);
    final coverage = recent.where((s) => s.covered).length / recent.length;
    final quality = _quality(
      coverage: coverage,
      validRatio: valid.length / beats.length,
      pulse: pulse,
      ibis: valid.map((b) => b.ibi).toList(),
    );
    return LiveEstimate(heartRate: 60 / SignalMath.median(valid.map((b) => b.ibi).toList()), quality: quality);
  }

  /// Normalised (-1..1) pulse waveform of the last [seconds] for display.
  static List<double> displayWaveform(List<PpgSample> recent, {double seconds = 4}) {
    if (recent.length < 20) return const [];
    final times = recent.map((s) => s.t).toList();
    final red = SignalMath.resampleUniform(times, recent.map((s) => s.red).toList(), fs);
    final pulse = BandPassFilter.filtfilt(red, fs, _hrLow, 4).map((v) => -v).toList();
    final keep = math.min(pulse.length, (seconds * fs).round());
    final tail = pulse.sublist(pulse.length - keep);
    final peak = tail.fold<double>(0, (m, v) => math.max(m, v.abs()));
    if (peak == 0) return List<double>.filled(tail.length, 0);
    return tail.map((v) => v / peak).toList();
  }

  // ------------------------------------------------------------------ internals

  static List<_Beat> _beats(List<double> peaks) {
    final raw = <_Beat>[];
    for (var i = 1; i < peaks.length; i++) {
      final ibi = (peaks[i] - peaks[i - 1]) / fs;
      raw.add(_Beat(start: peaks[i - 1], end: peaks[i], ibi: ibi, valid: ibi >= 0.33 && ibi <= 1.6));
    }
    final plausible = raw.where((b) => b.valid).map((b) => b.ibi).toList();
    if (plausible.isEmpty) return raw;
    final med = SignalMath.median(plausible);
    return raw.map((b) => b.valid && (b.ibi - med).abs() <= 0.25 * med ? b : b.copyWith(valid: false)).toList();
  }

  static ({double rmssd, double sdnn}) _hrv(List<_Beat> beats) {
    final diffs = <double>[];
    for (var i = 1; i < beats.length; i++) {
      if (beats[i].valid && beats[i - 1].valid) diffs.add(beats[i].ibi - beats[i - 1].ibi);
    }
    final rmssd = diffs.isEmpty
        ? 0.0
        : math.sqrt(diffs.map((d) => d * d).reduce((a, b) => a + b) / diffs.length) * 1000;
    final sdnn = SignalMath.std(beats.where((b) => b.valid).map((b) => b.ibi).toList()) * 1000;
    return (rmssd: rmssd, sdnn: sdnn);
  }

  static int _quality({
    required double coverage,
    required double validRatio,
    required List<double> pulse,
    required List<double> ibis,
  }) {
    // Beat consistency separates a real pulse from band-passed noise far better
    // than coverage (always ~1 once the finger is on): noise yields ~50% valid
    // beats with ~15% interval variation; a pulse gives >70% and <8%.
    final spectrum = SignalMath.dominantFrequency(
      pulse,
      fs,
      fMin: _hrLow,
      fMax: _hrHigh,
      step: 0.02,
      peakHalfWidth: 0.1,
    );
    final concentration = (spectrum.concentration / 0.5).clamp(0.0, 1.0);
    final cv = ibis.length < 2 ? 1.0 : SignalMath.std(ibis) / SignalMath.mean(ibis);
    final regularity = (1 - (cv - 0.04) / 0.10).clamp(0.0, 1.0);
    final consistency = ((validRatio - 0.5) / 0.4).clamp(0.0, 1.0);
    final score = 0.2 * coverage + 0.35 * consistency + 0.3 * regularity + 0.15 * concentration;
    return (score * 100).round().clamp(0, 100);
  }

  static double _perfusionIndex(List<double> pulse, List<double> raw) {
    final dc = SignalMath.mean(raw);
    if (dc <= 0) return 0;
    final ac = SignalMath.percentile(pulse, 0.95) - SignalMath.percentile(pulse, 0.05);
    return ac / dc * 100;
  }

  /// Respiration modulates both beat spacing (RSA) and beat amplitude. We take
  /// whichever series shows the clearer rhythm in the 6–30 breaths/min band.
  static double? _breathingRate(List<_Beat> valid, List<double> pulse) {
    if (valid.length < 10) return null;
    final t = valid.map((b) => (b.start + b.end) / 2 / fs).toList();
    if (t.last - t.first < 20) return null;

    final ibiSeries = valid.map((b) => b.ibi).toList();
    final ampSeries = valid.map((b) => pulse[b.end.round().clamp(0, pulse.length - 1)]).toList();

    ({double frequency, double concentration}) spectrum(List<double> y) {
      const rs = 4.0;
      final uniform = SignalMath.detrendLinear(SignalMath.resampleUniform(t, y, rs));
      return SignalMath.dominantFrequency(uniform, rs, fMin: 0.1, fMax: 0.5, step: 0.005, peakHalfWidth: 0.03);
    }

    final a = spectrum(ibiSeries);
    final b = spectrum(ampSeries);
    final best = a.concentration >= b.concentration ? a : b;
    if (best.concentration < 0.2 || best.frequency <= 0) return null;
    return (best.frequency * 60).clamp(6.0, 30.0);
  }

  /// Ratio-of-ratios with the red and blue channels. Experimental: phone
  /// cameras are not calibrated oximeters, so this is shown as "Beta".
  static double? _spo2(List<double> red, List<double> redBand, List<double> blue) {
    final dcR = SignalMath.mean(red);
    final dcB = SignalMath.mean(blue);
    if (dcR <= 0 || dcB < 2) return null;
    final acR = SignalMath.std(redBand);
    final acB = SignalMath.std(BandPassFilter.filtfilt(blue, fs, _hrLow, _hrHigh));
    if (acR <= 0 || acB <= 0) return null;
    final r = (acR / dcR) / (acB / dcB);
    final spo2 = AppConstants.spo2CoefA - AppConstants.spo2CoefB * r;
    if (!spo2.isFinite || spo2 < 80 || spo2 > 105) return null;
    return spo2.clamp(90.0, 100.0);
  }

  /// Averages foot-to-foot beats into one template and measures its shape.
  static PpgFeatures _features(List<double> signal, List<double> peaks, double perfusion) {
    const points = 60;
    final feet = <int>[];
    for (var i = 1; i < peaks.length; i++) {
      final a = peaks[i - 1].round(), b = peaks[i].round();
      var minIdx = a;
      for (var j = a; j <= b && j < signal.length; j++) {
        if (signal[j] < signal[minIdx]) minIdx = j;
      }
      feet.add(minIdx);
    }
    final template = List<double>.filled(points, 0);
    var used = 0;
    for (var i = 1; i < feet.length; i++) {
      final a = feet[i - 1], b = feet[i];
      final len = b - a;
      if (len < 0.33 * fs || len > 1.6 * fs) continue;
      final seg = signal.sublist(a, b + 1);
      final lo = seg.reduce(math.min), hi = seg.reduce(math.max);
      if (hi - lo <= 0) continue;
      for (var k = 0; k < points; k++) {
        final pos = k * (seg.length - 1) / (points - 1);
        final j = pos.floor();
        final frac = pos - j;
        final v = j + 1 < seg.length ? seg[j] + (seg[j + 1] - seg[j]) * frac : seg[j];
        template[k] += (v - lo) / (hi - lo);
      }
      used++;
    }
    if (used < 5) {
      return PpgFeatures(riseRatio: 0.2, reflectionIndex: 0.5, halfWidthRatio: 0.35, perfusionIndex: perfusion);
    }
    for (var k = 0; k < points; k++) {
      template[k] /= used;
    }

    var peakIdx = 0;
    for (var k = 1; k < points; k++) {
      if (template[k] > template[peakIdx]) peakIdx = k;
    }
    final peakVal = template[peakIdx] == 0 ? 1.0 : template[peakIdx];
    final halfWidth = template.where((v) => v >= 0.5 * peakVal).length / points;

    double? reflection;
    final from = math.min(points - 2, peakIdx + (0.1 * points).round());
    final to = math.min(points - 2, (0.85 * points).round());
    for (var k = from; k <= to; k++) {
      if (template[k] > template[k - 1] && template[k] >= template[k + 1]) {
        reflection = template[k] / peakVal;
        break;
      }
    }
    if (reflection == null && to > from) {
      var flattest = from;
      for (var k = from; k <= to; k++) {
        if ((template[k + 1] - template[k]).abs() < (template[flattest + 1] - template[flattest]).abs()) flattest = k;
      }
      reflection = template[flattest] / peakVal;
    }

    return PpgFeatures(
      riseRatio: peakIdx / (points - 1),
      reflectionIndex: (reflection ?? 0.5).clamp(0.0, 1.0),
      halfWidthRatio: halfWidth,
      perfusionIndex: perfusion,
    );
  }
}

class _Beat {
  const _Beat({required this.start, required this.end, required this.ibi, required this.valid});

  final double start;
  final double end;
  final double ibi;
  final bool valid;

  _Beat copyWith({bool? valid}) => _Beat(start: start, end: end, ibi: ibi, valid: valid ?? this.valid);
}
