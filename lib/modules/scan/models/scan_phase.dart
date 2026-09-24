enum ScanPhase { preparing, waitingForFinger, measuring, analyzing }

enum SignalLevel {
  searching('Checking signal'),
  poor('Signal: weak'),
  fair('Signal: fair'),
  good('Signal: good');

  const SignalLevel(this.label);
  final String label;

  static SignalLevel fromQuality(int? q) {
    if (q == null || q == 0) return SignalLevel.searching;
    if (q >= 65) return SignalLevel.good;
    if (q >= 45) return SignalLevel.fair;
    return SignalLevel.poor;
  }
}
