import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/check_tile.dart';
import '../../../widgets/entrance.dart';
import '../controllers/calibration_controller.dart';
import '../widgets/calibration_status_card.dart';

class CalibrationView extends GetView<CalibrationController> {
  const CalibrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const AppTopBar(title: 'Add cuff reading'),
              Expanded(
                child: Form(
                  key: c.formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 16),
                    children: [
                      Text(
                        AppStrings.calibrationIntro,
                        style: AppTextStyles.bodyLarge.copyWith(fontSize: 15),
                      ).entrance(0),
                      const SizedBox(height: 16),
                      Obx(
                        () => CalibrationStatusCard(
                          done: c.calibrationCount,
                          target: c.target,
                          linkedScan: c.linkedScan,
                          active: c.useForCalibration.value,
                        ),
                      ).entrance(1),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Systolic (top)',
                              controller: c.systolicCtrl,
                              suffix: 'mmHg',
                              hint: '120',
                              keyboardType: TextInputType.number,
                              inputFormatters: AppTextField.digits,
                              validator: Validators.systolic,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Diastolic (bottom)',
                              controller: c.diastolicCtrl,
                              suffix: 'mmHg',
                              hint: '80',
                              keyboardType: TextInputType.number,
                              inputFormatters: AppTextField.digits,
                              validator: Validators.diastolic,
                            ),
                          ),
                        ],
                      ).entrance(2),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Pulse (optional)',
                              controller: c.pulseCtrl,
                              suffix: 'bpm',
                              hint: '70',
                              keyboardType: TextInputType.number,
                              inputFormatters: AppTextField.digits,
                              validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.pulse(v),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Taken at', style: AppTextStyles.label),
                                const SizedBox(height: 6),
                                Obx(
                                  () => Material(
                                    color: AppColors.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      side: const BorderSide(color: AppColors.line),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      onTap: () => c.pickDateTime(context),
                                      child: Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.takenAt.value.friendly,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.body(15, weight: FontWeight.w500),
                                              ),
                                            ),
                                            const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.muted),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).entrance(3),
                      const SizedBox(height: 14),
                      Obx(
                        () => CheckTile(
                          value: c.useForCalibration.value,
                          onChanged: c.toggleCalibration,
                          label: 'Taken within 10 minutes of my last scan: use for calibration',
                        ),
                      ).entrance(4),
                      Obx(
                        () => CheckTile(
                          value: c.seatedLeftArm.value,
                          onChanged: (v) => c.seatedLeftArm.value = v,
                          label: 'Measured on left arm, seated',
                        ),
                      ).entrance(5),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
                child: Obx(
                  () => AppButton(
                    label: 'Save reading',
                    icon: Icons.check_rounded,
                    loading: c.saving.value,
                    onPressed: c.save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
