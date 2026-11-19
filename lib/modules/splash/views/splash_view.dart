import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/heartbeat.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  /// Matches the native splash (1024px artwork drawn at 4x), so the hand-off
  /// from the OS launch screen to Flutter is seamless.
  static const double _logoSize = 256;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        alignment: Alignment.center,
        children: [
          PulseHalo(
            color: Colors.white,
            size: _logoSize,
            child: Heartbeat(
              bpm: 66,
              amount: 0.06,
              child: Image.asset(
                AppAssets.logoMark,
                width: _logoSize,
                height: _logoSize,
                semanticLabel: '${AppConstants.appName} logo',
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.sizeOf(context).height / 2 + _logoSize * 0.36,
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.display(34, color: Colors.white),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 6),
                Text(
                  'Your well-being, brought to light',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(15, color: Colors.white70),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
