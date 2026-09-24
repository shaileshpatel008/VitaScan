import 'dart:math' as math;

/// Small numeric helpers used by the PPG pipeline. Pure Dart, isolate-safe.
class SignalMath {
  SignalMath._();

  static double mean(List<double> x) {
    if (x.isEmpty) return 0;
    var s = 0.0;
    for (final v in x) {
      s += v;
    }
    return s / x.length;
  }

  static double std(List<double> x) {
    if (x.length < 2) return 0;
    final m = mean(x);
    var s = 0.0;
    for (final v in x) {
      s += (v - m) * (v - m);
    }
    return math.sqrt(s / (x.length - 1));
  }

  static double percentile(List<double> x, double p) {
    if (x.isEmpty) return 0;
    final sorted = [...x]..sort();
    final pos = (sorted.length - 1) * p.clamp(0.0, 1.0);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
  }

  static double median(List<double> x) => percentile(x, 0.5);

  /// Linearly interpolates irregular samples onto a uniform grid at [fs] Hz.
  static List<double> resampleUniform(List<double> t, List<double> y, double fs) {
    if (t.length < 2) return [...y];
    final start = t.first;
    final end = t.last;
    final n = ((end - start) * fs).floor() + 1;
    final out = List<double>.filled(n, 0);
    var j = 0;
    for (var i = 0; i < n; i++) {
      final ti = start + i / fs;
      while (j < t.length - 2 && t[j + 1] < ti) {
        j++;
      }
      final t0 = t[j], t1 = t[j + 1];
      final dt = t1 - t0;
      final a = dt <= 0 ? 0.0 : ((ti - t0) / dt).clamp(0.0, 1.0);
      out[i] = y[j] + (y[j + 1] - y[j]) * a;
    }
    return out;
  }

  /// Removes the least-squares straight line from [x].
  static List<double> detrendLinear(List<double> x) {
    final n = x.length;
    if (n < 3) return [...x];
    final xm = (n - 1) / 2;
    final ym = mean(x);
    var num = 0.0, den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (i - xm) * (x[i] - ym);
      den += (i - xm) * (i - xm);
    }
    final slope = den == 0 ? 0.0 : num / den;
    return List<double>.generate(n, (i) => x[i] - (ym + slope * (i - xm)));
  }

  /// Returns the frequency with the most power in [fMin, fMax] and the share of
  /// in-band power concentrated around it (0..1, higher = cleaner rhythm).
  static ({double frequency, double concentration}) dominantFrequency(
    List<double> x,
    double fs, {
    required double fMin,
    required double fMax,
    double step = 0.01,
    double peakHalfWidth = 0.08,
  }) {
    if (x.length < 8) return (frequency: 0, concentration: 0);
    final freqs = <double>[];
    final powers = <double>[];
    for (var f = fMin; f <= fMax + 1e-9; f += step) {
      var re = 0.0, im = 0.0;
      final w = 2 * math.pi * f / fs;
      for (var i = 0; i < x.length; i++) {
        re += x[i] * math.cos(w * i);
        im -= x[i] * math.sin(w * i);
      }
      freqs.add(f);
      powers.add(re * re + im * im);
    }
    var best = 0;
    var total = 0.0;
    for (var i = 0; i < powers.length; i++) {
      total += powers[i];
      if (powers[i] > powers[best]) best = i;
    }
    if (total <= 0) return (frequency: 0, concentration: 0);
    var near = 0.0;
    for (var i = 0; i < powers.length; i++) {
      if ((freqs[i] - freqs[best]).abs() <= peakHalfWidth) near += powers[i];
    }
    return (frequency: freqs[best], concentration: near / total);
  }
}
