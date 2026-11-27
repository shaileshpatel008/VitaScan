import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../core/utils/health_classifier.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/calibration_repository.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../routes/app_routes.dart';

class ResultController extends GetxController {
  ResultController(this._readings, this._calibration, {ReviewService? reviews})
    : _reviews = reviews ?? (Get.isRegistered<ReviewService>() ? Get.find<ReviewService>() : null);

  final ReadingRepository _readings;
  final CalibrationRepository _calibration;
  final ReviewService? _reviews;

  late final String readingId;
  late final bool isFresh;
  late final bool lastFreeScan;
  final reading = Rxn<VitalReading>();

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    readingId = args['readingId'] as String? ?? '';
    isFresh = args['fresh'] as bool? ?? false;
    lastFreeScan = args['lastFreeScan'] as bool? ?? false;
    reading.value = _readings.byId(readingId);
  }

  @override
  void onReady() {
    super.onReady();
    final r = reading.value;
    if (r == null) {
      Get.back();
      AppMessenger.error('This reading could not be found.');
      return;
    }
    if (isFresh) Future.delayed(const Duration(milliseconds: 1400), () => _healthChecks(r));
  }

  /// Calm, clear guidance when a value is outside the usual range.
  Future<void> _healthChecks(VitalReading r) async {
    if (isClosed) return;
    final category = r.bpCategory;
    final unusualHr = r.heartRate != null && HeartRateStatus.isUnusual(r.heartRate!);
    if (category == BpCategory.crisis) {
      await AppMessenger.alert(
        title: AppStrings.highBpWarningTitle,
        message: AppStrings.crisisBpWarningBody,
        urgent: true,
      );
    } else if (category == BpCategory.stage2) {
      await AppMessenger.alert(title: AppStrings.highBpWarningTitle, message: AppStrings.highBpWarningBody);
    } else if (unusualHr) {
      await AppMessenger.alert(title: AppStrings.unusualHrTitle, message: AppStrings.unusualHrBody);
    }
    if (lastFreeScan) {
      AppMessenger.info(AppStrings.premiumLastFreeScan, title: 'Free scans used');
      return;
    }
    // Ask happy users for a rating, only after a clear, calm result.
    final askedForReview =
        await _reviews?.onScanResult(
          signalQuality: r.signalQuality,
          needsAttention: category?.needsAttention == true || unusualHr,
        ) ??
        false;
    if (isClosed || askedForReview) return;
    if (!r.isCalibrated && _calibration.count == 0 && r.bpCategory?.needsAttention != true) {
      AppMessenger.info(
        'Have a BP cuff nearby? Add a reading in the next 10 minutes to make your estimates personal.',
        title: 'Tip: calibrate your BP',
      );
    }
  }

  bool get canCalibrate {
    final r = reading.value;
    if (r == null || !r.isScan || r.rawSystolic == null) return false;
    final age = DateTime.now().difference(r.timestamp).inMinutes;
    return age <= AppConstants.calibrationMaxGapMinutes && !_calibration.isUsed(r.id);
  }

  void calibrate() => Get.toNamed(AppRoutes.calibration, arguments: {'scanReadingId': readingId});

  void done() {
    if (isFresh) {
      Get.until((route) => route.settings.name == AppRoutes.main || route.isFirst);
    } else {
      Get.back();
    }
  }

  Future<void> share() async {
    final r = reading.value;
    if (r == null) return;
    final lines = [
      '${AppConstants.appName} reading · ${r.timestamp.friendly}',
      if (r.hasBp) 'Blood pressure: ${r.bpText} mmHg${r.isScan ? ' (estimate)' : ' (cuff)'}',
      if (r.heartRate != null) 'Heart rate: ${r.heartRate} bpm',
      if (r.hrvRmssd != null) 'HRV: ${r.hrvRmssd!.round()} ms',
      if (r.breathingRate != null) 'Breathing: ${r.breathingRate}/min',
      if (r.spo2 != null) 'SpO2: ~${r.spo2}% (beta)',
      '',
      'Wellness estimate, not a medical diagnosis.',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: 'My ${AppConstants.appName} reading'));
  }

  Future<void> delete() async {
    final ok = await AppMessenger.confirm(
      title: 'Delete this reading?',
      message: 'It will be removed from your history and reports.',
      confirmText: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok) return;
    await _readings.delete(readingId);
    Get.back();
    AppMessenger.success('The reading was deleted.', title: 'Deleted');
  }
}
