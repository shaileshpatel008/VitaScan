import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/health_sync_service.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../data/models/calibration_point.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/calibration_repository.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../routes/app_routes.dart';
import '../../main_shell/controllers/main_shell_controller.dart';

class CalibrationController extends GetxController {
  CalibrationController(this._readings, this._calibration, this._settings, this._health);

  final ReadingRepository _readings;
  final CalibrationRepository _calibration;
  final SettingsRepository _settings;
  final HealthSyncService _health;

  final formKey = GlobalKey<FormState>();
  final systolicCtrl = TextEditingController();
  final diastolicCtrl = TextEditingController();
  final pulseCtrl = TextEditingController();

  final takenAt = DateTime.now().obs;
  final useForCalibration = false.obs;
  final seatedLeftArm = false.obs;
  final saving = false.obs;

  /// The scan this cuff reading can calibrate against, if any.
  VitalReading? linkedScan;

  int get calibrationCount => _calibration.points.length;
  int get target => AppConstants.calibrationTargetReadings;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    final id = args['scanReadingId'] as String?;
    final candidate = id != null ? _readings.byId(id) : _readings.latestScan;
    if (candidate != null && _isEligible(candidate, DateTime.now())) {
      linkedScan = candidate;
      useForCalibration.value = true;
    }
  }

  bool _isEligible(VitalReading scan, DateTime cuffTime) =>
      scan.isScan &&
      scan.rawSystolic != null &&
      !_calibration.isUsed(scan.id) &&
      cuffTime.difference(scan.timestamp).inMinutes.abs() <= AppConstants.calibrationMaxGapMinutes;

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: takenAt.value,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
      helpText: 'When was it measured?',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(takenAt.value));
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isAfter(now)) {
      AppMessenger.warning('The time can\'t be in the future.');
      return;
    }
    takenAt.value = picked;
    if (linkedScan != null && !_isEligible(linkedScan!, picked) && useForCalibration.value) {
      useForCalibration.value = false;
      AppMessenger.info(AppStrings.calibrationNoRecentScan, title: 'Saved as a log only');
    }
  }

  void toggleCalibration(bool value) {
    if (value && (linkedScan == null || !_isEligible(linkedScan!, takenAt.value))) {
      AppMessenger.info(AppStrings.calibrationNoRecentScan, title: 'No recent scan');
      return;
    }
    useForCalibration.value = value;
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) {
      AppMessenger.warning('Please check the highlighted values.', title: 'Almost there');
      return;
    }
    final sys = int.parse(systolicCtrl.text.trim());
    final dia = int.parse(diastolicCtrl.text.trim());
    final pulse = int.tryParse(pulseCtrl.text.trim());
    if (sys <= dia) {
      AppMessenger.warning(
        'The top number (systolic) should be higher than the bottom number (diastolic).',
        title: 'Please check the numbers',
      );
      return;
    }

    saving.value = true;
    final reading = VitalReading(
      id: const Uuid().v4(),
      timestamp: takenAt.value,
      source: ReadingSource.cuff,
      systolic: sys,
      diastolic: dia,
      heartRate: pulse,
      note: seatedLeftArm.value ? 'Measured on left arm, seated' : null,
    );
    await _readings.save(reading);
    if (_settings.current.healthSyncEnabled) unawaited(_health.sync(reading));

    final scan = linkedScan;
    var calibrated = false;
    if (useForCalibration.value && scan != null && _isEligible(scan, takenAt.value)) {
      await _calibration.add(
        CalibrationPoint(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          scanReadingId: scan.id,
          cuffSystolic: sys,
          cuffDiastolic: dia,
          estimatedSystolic: scan.rawSystolic!,
          estimatedDiastolic: scan.rawDiastolic!,
        ),
      );
      calibrated = true;
    }
    saving.value = false;

    Get.until((r) => r.settings.name == AppRoutes.main || r.isFirst);
    if (Get.isRegistered<MainShellController>()) Get.find<MainShellController>().changeTab(MainTab.history);

    if (!calibrated) {
      AppMessenger.success(AppStrings.calibrationSaved, title: 'Saved');
    } else if (_calibration.count == target) {
      AppMessenger.success(AppStrings.calibrationComplete, title: 'Calibration complete');
    } else {
      AppMessenger.success(
        '${AppStrings.calibrationStepSaved} (${_calibration.count.clamp(0, target)} of $target)',
        title: 'Calibration updated',
      );
    }
  }

  @override
  void onClose() {
    systolicCtrl.dispose();
    diastolicCtrl.dispose();
    pulseCtrl.dispose();
    super.onClose();
  }
}
