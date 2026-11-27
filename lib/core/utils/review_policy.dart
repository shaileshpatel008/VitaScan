/// When to ask for a Play Store rating.
///
/// Only after a good, calm result (never after a worrying reading or a poor
/// scan), from the 2nd good scan on, at most [maxPrompts] times and no more
/// than once every [cooldown]. Google Play also applies its own quota, so the
/// dialog may not appear even when this says yes.
class ReviewPolicy {
  ReviewPolicy._();

  static const int firstAfterGoodScans = 2;
  static const int maxPrompts = 3;
  static const Duration cooldown = Duration(days: 90);
  static const int minSignalQuality = 70;

  static bool isGoodResult({required int? signalQuality, required bool needsAttention}) =>
      !needsAttention && (signalQuality ?? 0) >= minSignalQuality;

  static bool shouldAsk({
    required int goodScans,
    required int timesAsked,
    required DateTime? lastAskedAt,
    required DateTime now,
  }) {
    if (goodScans < firstAfterGoodScans) return false;
    if (timesAsked >= maxPrompts) return false;
    if (lastAskedAt != null && now.difference(lastAskedAt) < cooldown) return false;
    return true;
  }
}
