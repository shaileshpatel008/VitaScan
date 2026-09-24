import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/finger_placement_illustration.dart';
import '../../../widgets/heartbeat.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_phase.dart';
import '../widgets/pulse_waveform.dart';
import '../widgets/scan_progress_ring.dart';

class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.cancelScan();
        },
        child: Scaffold(
          backgroundColor: AppColors.scanBackground,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(onClose: controller.cancelScan),
                Expanded(
                  child: Obx(() {
                    final phase = controller.phase.value;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      child: switch (phase) {
                        ScanPhase.preparing => const _Preparing(key: ValueKey('prep')),
                        ScanPhase.waitingForFinger => _WaitingForFinger(key: const ValueKey('wait'), c: controller),
                        _ => _Measuring(key: const ValueKey('measure'), c: controller),
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ScanController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel scan',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          Expanded(
            child: Obx(
              () => Text(
                switch (c.phase.value) {
                  ScanPhase.preparing || ScanPhase.waitingForFinger => 'Get ready',
                  ScanPhase.measuring => 'Scanning…',
                  ScanPhase.analyzing => 'Almost there',
                },
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ScanController>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(color: AppColors.scanAccent, strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Obx(() => Text(c.hint.value, style: AppTextStyles.body(15, color: Colors.white70))),
        ],
      ),
    );
  }
}

class _WaitingForFinger extends StatelessWidget {
  const _WaitingForFinger({super.key, required this.c});
  final ScanController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          PulseHalo(
            color: AppColors.scanAccent,
            size: 260,
            rings: 3,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const FingerPlacementIllustration(size: 170, dark: true),
            ),
          ),
          const SizedBox(height: 28),
          Obx(() => _FingerChip(detected: c.fingerDetected.value)),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              c.hint.value,
              textAlign: TextAlign.center,
              style: AppTextStyles.display(22, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The flash is on. It may feel slightly warm. That\'s normal.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(14, color: Colors.white.withValues(alpha: 0.7)),
          ),
          const Spacer(flex: 2),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _Measuring extends StatelessWidget {
  const _Measuring({super.key, required this.c});
  final ScanController c;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        children: [
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _FingerChip(detected: c.fingerDetected.value),
                _SignalChip(level: c.signalLevel),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Obx(() {
            final analyzing = c.phase.value == ScanPhase.analyzing;
            final hr = c.liveHeartRate.value;
            return ScanProgressRing(
              progress: c.progress.value,
              indeterminate: analyzing,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Heartbeat(
                        bpm: (hr ?? 70).toDouble(),
                        enabled: hr != null && !analyzing,
                        amount: 0.25,
                        child: const Icon(Icons.favorite_rounded, color: AppColors.scanAccent, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        analyzing ? 'Analysing' : 'Live pulse',
                        style: AppTextStyles.body(13, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
                    child: Text(
                      hr?.toString() ?? '--',
                      key: ValueKey(hr),
                      style: AppTextStyles.display(60, color: Colors.white).copyWith(height: 1),
                    ),
                  ),
                  Text('bpm', style: AppTextStyles.body(14, color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            );
          }),
          const SizedBox(height: 18),
          Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                c.phase.value == ScanPhase.analyzing ? 'Reading your results…' : '${c.secondsLeft.value} seconds left',
                key: ValueKey(c.phase.value == ScanPhase.analyzing ? -1 : c.secondsLeft.value),
                style: AppTextStyles.body(15, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => PulseWaveform(points: c.waveform.toList())),
          const SizedBox(height: 22),
          Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                c.hint.value,
                key: ValueKey(c.hint.value),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  15,
                  color: c.fingerDetected.value ? Colors.white.withValues(alpha: 0.85) : AppColors.flash,
                  weight: c.fingerDetected.value ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic);
  }
}

class _FingerChip extends StatelessWidget {
  const _FingerChip({required this.detected});
  final bool detected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: detected ? AppColors.scanChip : AppColors.amberSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            detected ? Icons.check_rounded : Icons.touch_app_rounded,
            size: 15,
            color: detected ? AppColors.scanChipText : AppColors.amber,
          ),
          const SizedBox(width: 5),
          Text(
            detected ? 'Finger detected' : 'Waiting for finger',
            style: AppTextStyles.body(
              12,
              weight: FontWeight.w700,
              color: detected ? AppColors.scanChipText : AppColors.amber,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.level});
  final SignalLevel level;

  @override
  Widget build(BuildContext context) {
    final good = level == SignalLevel.good || level == SignalLevel.fair;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: level == SignalLevel.poor
            ? AppColors.amberSoft
            : good
            ? AppColors.scanChip
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.label,
        style: AppTextStyles.body(
          12,
          weight: FontWeight.w700,
          height: 1.2,
          color: level == SignalLevel.poor
              ? AppColors.amber
              : good
              ? AppColors.scanChipText
              : Colors.white70,
        ),
      ),
    );
  }
}
