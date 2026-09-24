import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/finger_placement_illustration.dart';
import '../widgets/guide_step.dart';

class ScanGuideView extends StatelessWidget {
  const ScanGuideView({super.key});

  static const _steps = [
    ('Sit and rest for 1 minute', 'Keep your arm relaxed at heart level.'),
    ('Cover the rear camera and flash', 'Use your index fingertip. The flash will turn on and may feel warm.'),
    ('Touch lightly, don\'t press', 'Pressing hard blocks blood flow and spoils the reading.'),
    ('Stay still for 45 seconds', 'Breathe normally and don\'t talk.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: AppStrings.scanGuideTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.hero),
                      border: Border.all(color: AppColors.line),
                    ),
                    alignment: Alignment.center,
                    child: const FingerPlacementIllustration(size: 220),
                  ).entrance(0),
                  const SizedBox(height: 20),
                  for (var i = 0; i < _steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GuideStep(number: i + 1, title: _steps[i].$1, text: _steps[i].$2).entrance(i + 1),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
              child: Column(
                children: [
                  AppButton(
                    label: 'I\'m ready, start scan',
                    icon: Icons.monitor_heart_outlined,
                    onPressed: () => Get.toNamed(AppRoutes.scan),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Enter a cuff reading instead',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Get.toNamed(AppRoutes.calibration),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
