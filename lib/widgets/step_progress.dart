import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Segmented progress (e.g. onboarding steps, calibration 2 of 3).
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.total, required this.done, this.height = 6});

  final int total;
  final int done;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height),
              child: Stack(
                children: [
                  Container(height: height, color: AppColors.line),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: i < done ? 1 : 0),
                    duration: AppDurations.slow + Duration(milliseconds: 120 * i),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(height: height, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
