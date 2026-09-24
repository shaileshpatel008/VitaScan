import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/ppg/frame_color_extractor.dart';
import '../utils/ppg/ppg_models.dart';

class CameraUnavailableException implements Exception {
  const CameraUnavailableException([this.cause]);
  final Object? cause;
}

/// Opens the rear camera with the torch on and streams one [PpgSample] per frame.
class CameraPpgService {
  CameraController? _controller;
  DateTime? _startedAt;
  final _samples = StreamController<PpgSample>.broadcast();

  bool torchAvailable = true;

  Stream<PpgSample> get samples => _samples.stream;
  bool get isRunning => _controller?.value.isStreamingImages ?? false;

  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();
      if (back.isEmpty) throw const CameraUnavailableException('No rear camera');

      final controller = CameraController(
        back.first,
        ResolutionPreset.low,
        enableAudio: false,
        fps: AppConstants.cameraFps,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      _controller = controller;
      await controller.initialize();

      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (e) {
        torchAvailable = false;
        AppLogger.error('Torch unavailable', e);
      }
      try {
        await controller.setFocusMode(FocusMode.locked);
      } catch (_) {}

      _startedAt = null;
      await controller.startImageStream(_onFrame);
    } on CameraUnavailableException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Camera start failed', e, st);
      throw CameraUnavailableException(e);
    }
  }

  /// Locks exposure once the finger is in place so brightness changes come
  /// from blood volume, not from the camera adjusting itself.
  Future<void> lockExposure() async {
    try {
      await _controller?.setExposureMode(ExposureMode.locked);
    } catch (_) {}
  }

  void _onFrame(CameraImage image) {
    final rgb = FrameColorExtractor.averageRgb(image);
    if (rgb == null || _samples.isClosed) return;
    final now = DateTime.now();
    _startedAt ??= now;
    final covered =
        rgb.r >= AppConstants.fingerMinRed && rgb.r >= AppConstants.fingerRedDominance * math.max(rgb.g, 1.0);
    _samples.add(
      PpgSample(
        t: now.difference(_startedAt!).inMicroseconds / 1e6,
        red: rgb.r,
        green: rgb.g,
        blue: rgb.b,
        covered: covered,
      ),
    );
  }

  Future<void> stop() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      await c.setFlashMode(FlashMode.off);
    } catch (_) {}
    await c.dispose();
  }

  Future<void> dispose() async {
    await stop();
    await _samples.close();
  }
}
