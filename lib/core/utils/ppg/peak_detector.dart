import 'dart:math' as math;

/// Finds systolic peaks in a band-passed, inverted PPG signal.
class PeakDetector {
  PeakDetector._();

  /// Returns fractional sample positions of peaks (parabolic interpolation
  /// gives sub-frame timing, which matters for HRV at 30 fps).
  static List<double> detect(
    List<double> s,
    double fs, {
    double minIntervalSec = 0.33,
    double windowSec = 1.5,
    double relativeThreshold = 0.3,
  }) {
    final n = s.length;
    if (n < 3) return const [];
    final half = math.max(1, (windowSec * fs / 2).round());
    final minDist = (minIntervalSec * fs).round();

    final candidates = <int>[];
    for (var i = 1; i < n - 1; i++) {
      if (s[i] <= 0 || s[i] <= s[i - 1] || s[i] < s[i + 1]) continue;
      var localMax = 0.0;
      final lo = math.max(0, i - half), hi = math.min(n - 1, i + half);
      for (var j = lo; j <= hi; j++) {
        if (s[j] > localMax) localMax = s[j];
      }
      if (s[i] >= relativeThreshold * localMax) candidates.add(i);
    }

    candidates.sort((a, b) => s[b].compareTo(s[a]));
    final accepted = <int>[];
    for (final c in candidates) {
      if (accepted.every((a) => (a - c).abs() >= minDist)) accepted.add(c);
    }
    accepted.sort();

    return accepted.map((i) {
      final y0 = s[i - 1], y1 = s[i], y2 = s[i + 1];
      final den = y0 - 2 * y1 + y2;
      final delta = den == 0 ? 0.0 : (0.5 * (y0 - y2) / den).clamp(-0.5, 0.5);
      return i + delta;
    }).toList();
  }
}
