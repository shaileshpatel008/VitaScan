import 'dart:math' as math;

import '../../../data/models/calibration_point.dart';
import '../../../data/models/user_profile.dart';
import 'ppg_models.dart';

class BpEstimate {
  const BpEstimate(this.systolic, this.diastolic);
  final int systolic;
  final int diastolic;
}

/// Wellness-grade estimators built on top of [PpgAnalysisResult].
///
/// The BP model is a transparent linear baseline: population trends (age, BMI,
/// sex, known hypertension) plus pulse-shape features that correlate with
/// arterial stiffness. It is then shifted by the user's own cuff readings
/// (calibration), which is where most real-world accuracy comes from.
/// Re-fit these coefficients once you have paired scan + cuff data.
class VitalsEstimator {
  VitalsEstimator._();

  static BpEstimate estimateBp({
    required PpgFeatures features,
    required double heartRate,
    required UserProfile? profile,
  }) {
    final age = (profile?.age ?? 40).toDouble();
    final bmi = profile == null || profile.bmi <= 0 ? 24.0 : profile.bmi;
    final male = profile?.gender == Gender.male;
    final htn = profile?.hasHypertension ?? false;
    final treated = profile?.onBpMedication ?? false;

    var sys =
        112.0 +
        0.45 * (age - 40) +
        0.8 * (bmi - 24) +
        (male ? 3 : -2) +
        0.3 * (heartRate - 70) +
        22 * (features.reflectionIndex - 0.5) -
        30 * (features.riseRatio - 0.2) +
        (htn ? (treated ? 5 : 12) : 0);

    var dia =
        74.0 +
        0.18 * (age - 40) +
        0.5 * (bmi - 24) +
        (male ? 2 : 0) +
        0.25 * (heartRate - 70) +
        10 * (features.reflectionIndex - 0.5) -
        12 * (features.riseRatio - 0.2) +
        (htn ? (treated ? 3 : 7) : 0);

    sys = sys.clamp(85.0, 190.0);
    dia = dia.clamp(50.0, 120.0);
    final pulsePressure = (sys - dia).clamp(25.0, 75.0);
    dia = sys - pulsePressure;
    return BpEstimate(sys.round(), dia.round());
  }

  /// Applies the mean offset of the most recent calibration points.
  static BpEstimate calibrate(BpEstimate raw, List<CalibrationPoint> points) {
    if (points.isEmpty) return raw;
    final recent = [...points]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final use = recent.take(3).toList();
    final sysOffset = use.map((p) => p.systolicOffset).reduce((a, b) => a + b) / use.length;
    final diaOffset = use.map((p) => p.diastolicOffset).reduce((a, b) => a + b) / use.length;
    final sys = (raw.systolic + sysOffset).clamp(80.0, 220.0);
    final dia = (raw.diastolic + diaOffset).clamp(45.0, 140.0);
    return BpEstimate(sys.round(), math.min(dia.round(), sys.round() - 15));
  }

  /// 0 (relaxed) .. 100 (stressed) from parasympathetic activity (RMSSD) and HR.
  static int stressScore({required double rmssdMs, required double heartRate}) {
    final ln = math.log(rmssdMs.clamp(5.0, 150.0));
    final hrvPart = 1 - ((ln - math.log(10)) / (math.log(100) - math.log(10))).clamp(0.0, 1.0);
    final hrPart = ((heartRate - 60) / 40).clamp(0.0, 1.0);
    return ((0.75 * hrvPart + 0.25 * hrPart) * 100).round().clamp(0, 100);
  }
}
