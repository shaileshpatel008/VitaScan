import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

enum UpdateDialogIcon { available, ready }

/// Friendly update prompt. When [forced] it cannot be dismissed.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.newVersion,
    this.releaseNotes,
    this.forced = false,
    this.icon = UpdateDialogIcon.available,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;
  final String? newVersion;
  final String? releaseNotes;
  final bool forced;
  final UpdateDialogIcon icon;

  /// Returns true when the primary action was chosen.
  static Future<bool> show({
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
    String? newVersion,
    String? releaseNotes,
    bool forced = false,
    UpdateDialogIcon icon = UpdateDialogIcon.available,
  }) async {
    final result = await Get.dialog<bool>(
      UpdateDialog(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: forced ? null : secondaryLabel,
        newVersion: newVersion,
        releaseNotes: releaseNotes,
        forced: forced,
        icon: icon,
      ),
      barrierDismissible: !forced,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final notes = releaseNotes?.trim();
    return PopScope(
      canPop: !forced,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.hero)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: forced ? AppColors.amberSoft : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon == UpdateDialogIcon.ready ? Icons.restart_alt_rounded : Icons.system_update_rounded,
                      color: forced ? AppColors.amber : AppColors.primary,
                      size: 30,
                    ),
                  )
                  .animate()
                  .scale(begin: const Offset(0.6, 0.6), duration: 450.ms, curve: Curves.easeOutBack)
                  .then()
                  .moveY(begin: 0, end: -4, duration: 600.ms, curve: Curves.easeInOut)
                  .then()
                  .moveY(begin: -4, end: 0, duration: 600.ms, curve: Curves.easeInOut),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.h3),
              if (newVersion != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Version $newVersion',
                  style: AppTextStyles.body(13, color: AppColors.primary, weight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What\'s new', style: AppTextStyles.body(13, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(notes, style: AppTextStyles.body(13, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(label: primaryLabel, icon: Icons.download_rounded, onPressed: () => Get.back(result: true)),
              if (secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: secondaryLabel!,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Get.back(result: false),
                ),
              ],
            ],
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
    );
  }
}
