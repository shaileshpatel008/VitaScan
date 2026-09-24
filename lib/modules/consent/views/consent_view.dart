import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/check_tile.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/step_progress.dart';
import '../controllers/consent_controller.dart';
import '../widgets/info_row.dart';

class ConsentView extends GetView<ConsentController> {
  const ConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Before you start',
              showBack: Navigator.of(context).canPop(),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('Step 2 of 2', style: AppTextStyles.bodySmall),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: StepProgress(total: 2, done: 2, height: 4),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 20, AppSpacing.screen, 16),
                children: [
                  Text(AppStrings.consentTitle, style: AppTextStyles.h2).entrance(0),
                  const SizedBox(height: 18),
                  const InfoRow(
                    icon: Icons.shield_outlined,
                    title: AppStrings.consentWellnessTitle,
                    text: AppStrings.consentWellnessBody,
                  ).entrance(1),
                  const SizedBox(height: 18),
                  const InfoRow(
                    icon: Icons.photo_camera_outlined,
                    title: AppStrings.consentCameraTitle,
                    text: AppStrings.consentCameraBody,
                  ).entrance(2),
                  const SizedBox(height: 18),
                  const InfoRow(
                    icon: Icons.lock_outline_rounded,
                    title: AppStrings.consentDataTitle,
                    text: AppStrings.consentDataBody,
                  ).entrance(3),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.consentEmergency,
                            style: AppTextStyles.body(13, color: AppColors.amber),
                          ),
                        ),
                      ],
                    ),
                  ).entrance(4),
                  const SizedBox(height: 18),
                  Obx(
                    () => CheckTile(
                      value: c.acceptedEstimate.value,
                      onChanged: (v) => c.acceptedEstimate.value = v,
                      label: AppStrings.consentCheckEstimate,
                    ),
                  ).entrance(5),
                  Obx(
                    () => CheckTile(
                      value: c.acceptedTerms.value,
                      onChanged: (v) => c.acceptedTerms.value = v,
                      label: AppStrings.consentCheckTerms,
                    ),
                  ).entrance(6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(onPressed: c.showTerms, child: const Text('Read Terms & Privacy Policy')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
              child: Obx(
                () => AnimatedOpacity(
                  duration: AppDurations.medium,
                  opacity: c.canContinue ? 1 : 0.6,
                  child: AppButton(
                    label: 'Allow camera & continue',
                    icon: Icons.photo_camera_outlined,
                    loading: c.busy.value,
                    onPressed: c.continueTapped,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
