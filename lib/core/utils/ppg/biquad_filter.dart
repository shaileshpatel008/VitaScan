import 'dart:math' as math;

/// Second-order IIR section (RBJ audio-EQ cookbook coefficients).
class Biquad {
  Biquad._(this.b0, this.b1, this.b2, this.a1, this.a2);

  final double b0, b1, b2, a1, a2;

  factory Biquad.lowPass(double fs, double fc, {double q = 0.7071}) {
    final w0 = 2 * math.pi * fc / fs;
    final alpha = math.sin(w0) / (2 * q);
    final cosW = math.cos(w0);
    final a0 = 1 + alpha;
    return Biquad._((1 - cosW) / 2 / a0, (1 - cosW) / a0, (1 - cosW) / 2 / a0, -2 * cosW / a0, (1 - alpha) / a0);
  }

  factory Biquad.highPass(double fs, double fc, {double q = 0.7071}) {
    final w0 = 2 * math.pi * fc / fs;
    final alpha = math.sin(w0) / (2 * q);
    final cosW = math.cos(w0);
    final a0 = 1 + alpha;
    return Biquad._((1 + cosW) / 2 / a0, -(1 + cosW) / a0, (1 + cosW) / 2 / a0, -2 * cosW / a0, (1 - alpha) / a0);
  }

  List<double> apply(List<double> x) {
    final y = List<double>.filled(x.length, 0);
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    for (var i = 0; i < x.length; i++) {
      final xi = x[i];
      final yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      x2 = x1;
      x1 = xi;
      y2 = y1;
      y1 = yi;
      y[i] = yi;
    }
    return y;
  }
}

/// Zero-phase band-pass (4th-order high-pass + 4th-order low-pass, run forward
/// and backward) so pulse peaks are not shifted in time.
class BandPassFilter {
  BandPassFilter._();

  static List<double> filtfilt(List<double> x, double fs, double low, double high) {
    if (x.length < 4) return [...x];
    final sections = [
      Biquad.highPass(fs, low),
      Biquad.highPass(fs, low),
      Biquad.lowPass(fs, high),
      Biquad.lowPass(fs, high),
    ];
    final pad = math.min((3 * fs).round(), x.length - 1);
    final padded = _reflectPad(x, pad);

    var y = padded;
    for (final s in sections) {
      y = s.apply(y);
    }
    y = y.reversed.toList();
    for (final s in sections) {
      y = s.apply(y);
    }
    y = y.reversed.toList();
    return y.sublist(pad, pad + x.length);
  }

  static List<double> _reflectPad(List<double> x, int pad) {
    final first = x.first, last = x.last;
    final pre = List<double>.generate(pad, (i) => 2 * first - x[pad - i]);
    final post = List<double>.generate(pad, (i) => 2 * last - x[x.length - 2 - i]);
    return [...pre, ...x, ...post];
  }
}
