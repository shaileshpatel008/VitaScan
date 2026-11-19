import 'package:get/get.dart';
import 'package:health/health.dart';

import '../../data/models/vital_reading.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Writes readings to Google Health Connect / Apple Health.
///
/// Camera BP values are estimates, so only cuff BP readings are written as
/// blood pressure; heart rate and breathing rate are written for scans.
class HealthSyncService extends GetxService {
  final _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> connect() async {
    if (!AppConstants.enableHealthSync) return false;
    try {
      await _configure();
      // Write-only: the app never reads from Health, so it asks for no read access.
      return await _health.requestAuthorization(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.WRITE),
      );
    } catch (e, st) {
      AppLogger.error('Health authorization failed', e, st);
      return false;
    }
  }

  Future<void> sync(VitalReading r) async {
    if (!AppConstants.enableHealthSync) return;
    try {
      await _configure();
      final start = r.timestamp;
      final end = start.add(const Duration(seconds: 45));
      final method = r.isScan ? RecordingMethod.automatic : RecordingMethod.manual;
      if (r.heartRate != null) {
        await _health.writeHealthData(
          value: r.heartRate!.toDouble(),
          type: HealthDataType.HEART_RATE,
          startTime: start,
          endTime: end,
          recordingMethod: method,
        );
      }
      if (r.breathingRate != null) {
        await _health.writeHealthData(
          value: r.breathingRate!.toDouble(),
          type: HealthDataType.RESPIRATORY_RATE,
          startTime: start,
          endTime: end,
          recordingMethod: method,
        );
      }
      if (!r.isScan && r.hasBp) {
        await _health.writeBloodPressure(
          systolic: r.systolic!,
          diastolic: r.diastolic!,
          startTime: start,
          recordingMethod: RecordingMethod.manual,
        );
      }
    } catch (e, st) {
      AppLogger.error('Health sync failed', e, st);
    }
  }
}
