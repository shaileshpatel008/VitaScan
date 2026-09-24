import 'dart:ui';

import '../../theme/app_colors.dart';

/// Blood pressure categories (American Heart Association, 2017).
enum BpCategory {
  normal('Normal', 'Within normal range', AppColors.bpNormal),
  elevated('Elevated', 'Slightly above normal', AppColors.bpElevated),
  stage1('High (stage 1)', 'Higher than normal', AppColors.bpStage1),
  stage2('High (stage 2)', 'High: please confirm with a cuff', AppColors.bpStage2),
  crisis('Very high', 'Very high: confirm now', AppColors.bpStage2);

  const BpCategory(this.label, this.description, this.color);

  final String label;
  final String description;
  final Color color;

  static BpCategory classify(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return BpCategory.crisis;
    if (systolic >= 140 || diastolic >= 90) return BpCategory.stage2;
    if (systolic >= 130 || diastolic >= 80) return BpCategory.stage1;
    if (systolic >= 120) return BpCategory.elevated;
    return BpCategory.normal;
  }

  bool get needsAttention => this == BpCategory.stage2 || this == BpCategory.crisis;

  /// Position (0..1) of a systolic value on the 4-segment range bar.
  static double barPosition(int systolic) {
    const stops = [90.0, 120.0, 130.0, 140.0, 180.0];
    const marks = [0.0, 0.375, 0.5, 0.75, 1.0];
    final s = systolic.toDouble().clamp(stops.first, stops.last);
    for (var i = 1; i < stops.length; i++) {
      if (s <= stops[i]) {
        final f = (s - stops[i - 1]) / (stops[i] - stops[i - 1]);
        return marks[i - 1] + (marks[i] - marks[i - 1]) * f;
      }
    }
    return 1;
  }
}

enum StressLevel {
  low('Low'),
  moderate('Moderate'),
  high('High');

  const StressLevel(this.label);
  final String label;

  static StressLevel fromScore(int score) {
    if (score < 40) return StressLevel.low;
    if (score < 70) return StressLevel.moderate;
    return StressLevel.high;
  }
}

class HeartRateStatus {
  HeartRateStatus._();

  static String describe(int bpm) {
    if (bpm < 50) return 'Low for resting';
    if (bpm <= 100) return 'Resting · normal';
    if (bpm <= 120) return 'A little high';
    return 'High for resting';
  }

  static bool isUnusual(int bpm) => bpm < 45 || bpm > 130;

  static String hrvLabel(double rmssd) {
    if (rmssd >= 40) return 'Good recovery';
    if (rmssd >= 20) return 'Average';
    return 'Low: rest more';
  }

  static String breathingLabel(int rpm) {
    if (rpm < 10) return 'Slow';
    if (rpm <= 20) return 'Normal';
    return 'Fast';
  }
}
