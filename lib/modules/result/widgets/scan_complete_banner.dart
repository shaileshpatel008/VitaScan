import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class ScanCompleteBanner extends StatelessWidget {
  const ScanCompleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: Row(
        children: [
          Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              )
              .animate()
              .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut)
              .then(delay: 200.ms)
              .shimmer(duration: 900.ms, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan complete',
                  style: AppTextStyles.body(15, weight: FontWeight.w700, color: AppColors.primaryDark),
                ),
                Text(
                  'Great job holding still. Your reading is saved.',
                  style: AppTextStyles.body(13, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic);
  }
}
