import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/heartbeat.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseHalo(
              color: Colors.white,
              size: 170,
              child: Heartbeat(
                bpm: 66,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, color: AppColors.primary, size: 44),
                ),
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 18),
            Text(
              AppConstants.appName,
              style: AppTextStyles.display(34, color: Colors.white),
            ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 6),
            Text(
              'Your pulse, at your fingertip',
              style: AppTextStyles.body(15, color: Colors.white70),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
