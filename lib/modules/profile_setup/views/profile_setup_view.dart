import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/check_tile.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/segmented_selector.dart';
import '../../../widgets/step_progress.dart';
import '../controllers/profile_setup_controller.dart';

class ProfileSetupView extends GetView<ProfileSetupController> {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: c.isEditing ? 'Edit profile' : AppStrings.profileTitle,
                trailing: c.isEditing
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('Step 1 of 2', style: AppTextStyles.bodySmall),
                      ),
              ),
              if (!c.isEditing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: StepProgress(total: 2, done: 1, height: 4),
                ),
              Expanded(
                child: Form(
                  key: c.formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 20, AppSpacing.screen, 16),
                    children: [
                      Text(AppStrings.profileIntro, style: AppTextStyles.bodyLarge).entrance(0),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: 'Full name',
                        controller: c.nameCtrl,
                        hint: 'e.g. John Smith',
                        validator: Validators.name,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 40,
                      ).entrance(1),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Age',
                              controller: c.ageCtrl,
                              suffix: 'yrs',
                              keyboardType: TextInputType.number,
                              inputFormatters: AppTextField.digits,
                              validator: Validators.age,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Height',
                              controller: c.heightCtrl,
                              suffix: 'cm',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: AppTextField.decimal,
                              validator: Validators.heightCm,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Weight',
                              controller: c.weightCtrl,
                              suffix: 'kg',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: AppTextField.decimal,
                              validator: Validators.weightKg,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ).entrance(2),
                      const SizedBox(height: 16),
                      Text('Gender', style: AppTextStyles.label).entrance(3),
                      const SizedBox(height: 6),
                      Obx(
                        () => SegmentedSelector<Gender>(
                          options: Gender.values,
                          selected: c.gender.value,
                          onChanged: (g) => c.gender.value = g,
                          labelOf: (g) => g.label,
                        ),
                      ).entrance(3),
                      const SizedBox(height: 20),
                      Text('Health background (optional)', style: AppTextStyles.label).entrance(4),
                      const SizedBox(height: 6),
                      Obx(
                        () => Column(
                          children: [
                            CheckTile(
                              value: c.hasHypertension.value,
                              onChanged: (v) => c.hasHypertension.value = v,
                              label: 'Diagnosed with high blood pressure',
                            ),
                            CheckTile(
                              value: c.onBpMedication.value,
                              onChanged: (v) => c.onBpMedication.value = v,
                              label: 'Taking blood pressure medication',
                            ),
                            CheckTile(
                              value: c.hasDiabetes.value,
                              onChanged: (v) => c.hasDiabetes.value = v,
                              label: 'Diabetes',
                            ),
                          ],
                        ),
                      ).entrance(5),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Stored encrypted on this phone only.', style: AppTextStyles.caption)),
                        ],
                      ).entrance(6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
                child: Obx(
                  () => AppButton(
                    label: c.isEditing ? 'Save changes' : 'Continue',
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
