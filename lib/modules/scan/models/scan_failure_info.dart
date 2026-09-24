import 'package:flutter/material.dart';

import '../../../core/utils/ppg/ppg_models.dart';

/// Patient-friendly explanation for each way a scan can fail.
class ScanFailureInfo {
  const ScanFailureInfo({required this.title, required this.reason, required this.tips, required this.icon});

  final String title;
  final String reason;
  final List<String> tips;
  final IconData icon;

  static const _baseTips = [
    'Cover both the camera and the flash',
    'Touch lightly, don\'t press',
    'Warm up cold fingers first',
    'Rest your hand on a table so it stays still',
  ];

  factory ScanFailureInfo.of(ScanFailureReason? reason) => switch (reason) {
    ScanFailureReason.fingerNotDetected => const ScanFailureInfo(
      title: 'We couldn\'t see your fingertip',
      reason: 'The camera did not detect a finger for long enough.',
      tips: [
        'Place your index fingertip over the rear camera',
        'Make sure the flash is covered too',
        'Scan in a normally lit room',
      ],
      icon: Icons.touch_app_rounded,
    ),
    ScanFailureReason.fingerMoved => const ScanFailureInfo(
      title: 'Your finger moved during the scan',
      reason: 'Keeping still for 45 seconds gives the clearest pulse.',
      tips: _baseTips,
      icon: Icons.pan_tool_alt_rounded,
    ),
    ScanFailureReason.weakSignal => const ScanFailureInfo(
      title: 'The pulse signal was too weak',
      reason: 'This usually means pressing too hard or cold hands.',
      tips: [
        'Press more lightly: just rest your finger',
        'Rub your hands together to warm them',
        'Keep your hand at heart level',
        'Cover both the camera and the flash',
      ],
      icon: Icons.signal_cellular_alt_1_bar_rounded,
    ),
    ScanFailureReason.noPulse => const ScanFailureInfo(
      title: 'We couldn\'t get a clear pulse signal',
      reason: 'This happens often. A second try usually works.',
      tips: _baseTips,
      icon: Icons.monitor_heart_outlined,
    ),
    ScanFailureReason.tooShort => const ScanFailureInfo(
      title: 'The scan was too short',
      reason: 'We need about 45 seconds of steady contact.',
      tips: ['Keep your finger in place until the ring is full', 'Breathe normally and don\'t talk'],
      icon: Icons.timer_outlined,
    ),
    ScanFailureReason.lowFrameRate => const ScanFailureInfo(
      title: 'The camera was running slowly',
      reason: 'Your phone may be busy or in battery-saver mode.',
      tips: ['Close other apps', 'Turn off battery saver', 'Try again in a moment'],
      icon: Icons.speed_rounded,
    ),
    null => const ScanFailureInfo(
      title: 'The scan was interrupted',
      reason: 'Something went wrong while scanning.',
      tips: _baseTips,
      icon: Icons.error_outline_rounded,
    ),
  };
}
