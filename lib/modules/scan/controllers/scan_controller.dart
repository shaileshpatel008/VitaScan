import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/camera_ppg_service.dart';
import '../../../core/services/health_sync_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../core/utils/ppg/ppg_analyzer.dart';
import '../../../core/utils/ppg/ppg_models.dart';
import '../../../core/utils/ppg/vitals_estimator.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/calibration_repository.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';
import '../models/scan_phase.dart';

class ScanController extends GetxController with WidgetsBindingObserver {
  ScanController({
    required this._camera,
    required this._readings,
    required this._users,
    required this._calibration,
    required this._settings,
    required this._health,
    required this._permissions,
  });

  final CameraPpgService _camera;
  final ReadingRepository _readings;
  final UserRepository _users;
  final CalibrationRepository _calibration;
  final SettingsRepository _settings;
  final HealthSyncService _health;
  final PermissionService _permissions;

  static const _duration = AppConstants.scanDurationSeconds;

  final phase = ScanPhase.preparing.obs;
  final progress = 0.0.obs;
  final secondsLeft = _duration.obs;
  final liveHeartRate = RxnInt();
  final signalQuality = 0.obs;
  final fingerDetected = false.obs;
  final waveform = <double>[].obs;
  final hint = AppStrings.scanPreparing.obs;

  SignalLevel get signalLevel => SignalLevel.fromQuality(signalQuality.value);

  final List<PpgSample> _samples = [];
  StreamSubscription<PpgSample>? _sub;
  Timer? _ticker;
  double? _coveredSince;
  double? _lostSince;
  double? _lastT;
  double _measured = 0;
  double _lastLiveAt = 0;
  bool _finished = false;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    if (!await _permissions.ensureCamera()) {
      Get.back();
      return;
    }
    try {
      await _camera.start();
    } on CameraUnavailableException {
      AppMessenger.error(AppStrings.cameraUnavailable, title: 'Camera unavailable');
      Get.back();
      return;
    }
    if (isClosed) return;
    WidgetsBinding.instance.addObserver(this);
    if (!_camera.torchAvailable) AppMessenger.warning(AppStrings.noFlash);
    await WakelockPlus.enable();

    phase.value = ScanPhase.waitingForFinger;
    hint.value = AppStrings.scanPlaceFinger;
    _sub = _camera.samples.listen(_onSample);
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _onSample(PpgSample s) {
    if (_finished) return;
    fingerDetected.value = s.covered;

    switch (phase.value) {
      case ScanPhase.waitingForFinger:
        if (s.covered) {
          _coveredSince ??= s.t;
          if (s.t - _coveredSince! >= AppConstants.fingerHoldToStartSeconds) _beginMeasuring();
        } else {
          _coveredSince = null;
        }
      case ScanPhase.measuring:
        _samples.add(s);
        final dt = _lastT == null ? 0.0 : (s.t - _lastT!).clamp(0.0, 0.2);
        _lastT = s.t;
        if (s.covered) {
          if (_lostSince != null) {
            _lostSince = null;
            hint.value = AppStrings.scanHoldStill;
          }
          _measured += dt;
        } else {
          _lostSince ??= s.t;
          hint.value = AppStrings.scanFingerLost;
          if (s.t - _lostSince! > AppConstants.maxFingerLostSeconds) {
            _fail(ScanFailureReason.fingerMoved);
            return;
          }
        }
        if (_measured >= _duration) _complete();
      case ScanPhase.preparing:
      case ScanPhase.analyzing:
        break;
    }
  }

  void _beginMeasuring() {
    phase.value = ScanPhase.measuring;
    HapticFeedback.mediumImpact();
    hint.value = AppStrings.scanFingerFound;
    _camera.lockExposure();
    _samples.clear();
    _lastT = null;
    _measured = 0;
    Future.delayed(const Duration(seconds: 3), () {
      if (phase.value == ScanPhase.measuring && _lostSince == null) hint.value = AppStrings.scanHoldStill;
    });
  }

  void _tick() {
    if (phase.value != ScanPhase.measuring || _samples.isEmpty) return;
    progress.value = (_measured / _duration).clamp(0.0, 1.0);
    secondsLeft.value = (_duration - _measured).ceil().clamp(0, _duration);
    if (progress.value > 0.75 && _lostSince == null && hint.value == AppStrings.scanHoldStill) {
      hint.value = AppStrings.scanAlmostDone;
    }

    final now = _samples.last.t;
    waveform.assignAll(PpgAnalyzer.displayWaveform(_recent(6)));

    if (_measured >= AppConstants.liveHrMinSeconds && now - _lastLiveAt >= 1) {
      _lastLiveAt = now;
      final est = PpgAnalyzer.quickEstimate(_recent(AppConstants.liveHrWindowSeconds));
      signalQuality.value = est.quality;
      if (est.heartRate != null) liveHeartRate.value = est.heartRate!.round();
    }
  }

  List<PpgSample> _recent(double seconds) {
    if (_samples.isEmpty) return const [];
    final from = _samples.last.t - seconds;
    var i = _samples.length - 1;
    while (i > 0 && _samples[i - 1].t >= from) {
      i--;
    }
    return _samples.sublist(i);
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    phase.value = ScanPhase.analyzing;
    progress.value = 1;
    secondsLeft.value = 0;
    hint.value = AppStrings.scanAnalyzing;
    HapticFeedback.heavyImpact();
    await _shutdown();

    final samples = List<PpgSample>.of(_samples);
    PpgAnalysisResult result;
    try {
      result = await Isolate.run(() => PpgAnalyzer.analyze(samples));
    } catch (e, st) {
      AppLogger.error('Analysis failed', e, st);
      result = PpgAnalysisResult.failed(ScanFailureReason.noPulse);
    }
    // Give the "analysing" animation a moment so the transition feels calm.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!result.success) {
      Get.offNamed(AppRoutes.poorSignal, arguments: result.failure);
      return;
    }

    final reading = _buildReading(result);
    await _readings.save(reading);
    if (_settings.current.healthSyncEnabled) unawaited(_health.sync(reading));
    // Only successful scans use up a free scan.
    final usedLastFreeScan = await Get.find<PurchaseService>().recordSuccessfulScan();
    Get.offNamed(
      AppRoutes.result,
      arguments: {'readingId': reading.id, 'fresh': true, 'lastFreeScan': usedLastFreeScan},
    );
  }

  VitalReading _buildReading(PpgAnalysisResult r) {
    final raw = VitalsEstimator.estimateBp(features: r.features, heartRate: r.heartRate, profile: _users.profile.value);
    final calibrated = VitalsEstimator.calibrate(raw, _calibration.points);
    return VitalReading(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      source: ReadingSource.scan,
      systolic: calibrated.systolic,
      diastolic: calibrated.diastolic,
      heartRate: r.heartRate.round(),
      hrvRmssd: double.parse(r.rmssdMs.toStringAsFixed(1)),
      stressScore: VitalsEstimator.stressScore(rmssdMs: r.rmssdMs, heartRate: r.heartRate),
      breathingRate: r.breathingRate?.round(),
      spo2: AppConstants.showSpo2Estimate ? r.spo2?.round() : null,
      signalQuality: r.quality,
      rawSystolic: raw.systolic,
      rawDiastolic: raw.diastolic,
      isCalibrated: _calibration.points.isNotEmpty,
    );
  }

  Future<void> _fail(ScanFailureReason reason) async {
    if (_finished) return;
    _finished = true;
    HapticFeedback.heavyImpact();
    await _shutdown();
    Get.offNamed(AppRoutes.poorSignal, arguments: reason);
  }

  Future<void> cancelScan() async {
    if (phase.value == ScanPhase.analyzing) return;
    if (phase.value == ScanPhase.measuring) {
      final stop = await AppMessenger.confirm(
        title: AppStrings.scanStopTitle,
        message: AppStrings.scanStopBody,
        confirmText: AppStrings.scanStopConfirm,
        cancelText: AppStrings.scanKeepGoing,
        destructive: true,
        icon: Icons.stop_circle_outlined,
      );
      if (!stop || _finished) return;
    }
    _finished = true;
    await _shutdown();
    Get.back();
  }

  Future<void> _shutdown() async {
    _ticker?.cancel();
    _ticker = null;
    await _sub?.cancel();
    _sub = null;
    await _camera.stop();
    await WakelockPlus.disable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _finished = true;
      _shutdown();
      Get.back();
      AppMessenger.warning(AppStrings.scanInterruptedBackground, title: 'Scan stopped');
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _sub?.cancel();
    _camera.dispose();
    WakelockPlus.disable();
    super.onClose();
  }
}
