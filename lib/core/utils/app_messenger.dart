import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../constants/app_strings.dart';

enum MessageType { success, info, warning, error }

/// One place for every toast and dialog, so tone and look stay consistent.
class AppMessenger {
  AppMessenger._();

  static void success(String message, {String title = 'Done'}) => _show(MessageType.success, title, message);
  static void info(String message, {String title = 'Good to know'}) => _show(MessageType.info, title, message);
  static void warning(String message, {String title = 'Heads up'}) => _show(MessageType.warning, title, message);
  static void error(String message, {String title = 'Something went wrong'}) =>
      _show(MessageType.error, title, message);

  static void _show(MessageType type, String title, String message) {
    final (bg, fg, icon) = switch (type) {
      MessageType.success => (AppColors.primarySoft, AppColors.primaryDark, Icons.check_circle_rounded),
      MessageType.info => (AppColors.surface, AppColors.ink, Icons.info_rounded),
      MessageType.warning => (AppColors.amberSoft, AppColors.amber, Icons.warning_amber_rounded),
      MessageType.error => (AppColors.coralSoft, AppColors.coral, Icons.error_rounded),
    };
    if (type == MessageType.error || type == MessageType.warning) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: bg,
      colorText: fg,
      borderColor: fg.withValues(alpha: 0.18),
      borderWidth: 1,
      borderRadius: AppRadius.card,
      margin: const EdgeInsets.all(AppSpacing.lg),
      icon: Icon(icon, color: fg),
      shouldIconPulse: type == MessageType.warning || type == MessageType.error,
      duration: Duration(seconds: type == MessageType.error ? 5 : 3),
      animationDuration: AppDurations.medium,
      forwardAnimationCurve: Curves.easeOutBack,
      titleText: Text(
        title,
        style: AppTextStyles.body(15, weight: FontWeight.w700, color: fg),
      ),
      messageText: Text(message, style: AppTextStyles.body(14, color: fg)),
      boxShadows: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
    );
  }

  /// Friendly confirmation dialog. Returns true when the user confirms.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = AppStrings.ok,
    String cancelText = AppStrings.cancel,
    bool destructive = false,
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final result = await Get.dialog<bool>(
      _AppDialog(
        title: title,
        message: message,
        icon: icon,
        tone: destructive ? AppColors.coral : AppColors.primary,
        toneSoft: destructive ? AppColors.coralSoft : AppColors.primarySoft,
        primaryText: confirmText,
        secondaryText: cancelText,
      ),
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
    return result ?? false;
  }

  /// Important health notice with a single acknowledgement button.
  static Future<void> alert({
    required String title,
    required String message,
    String buttonText = 'I understand',
    bool urgent = false,
  }) async {
    HapticFeedback.heavyImpact();
    await Get.dialog<bool>(
      _AppDialog(
        title: title,
        message: message,
        icon: urgent ? Icons.emergency_rounded : Icons.favorite_rounded,
        tone: urgent ? AppColors.coral : AppColors.amber,
        toneSoft: urgent ? AppColors.coralSoft : AppColors.amberSoft,
        primaryText: buttonText,
      ),
      barrierDismissible: false,
    );
  }
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
    required this.toneSoft,
    required this.primaryText,
    this.secondaryText,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color tone;
  final Color toneSoft;
  final String primaryText;
  final String? secondaryText;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: toneSoft, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: tone, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  if (secondaryText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                        ),
                        child: Text(secondaryText!, style: AppTextStyles.body(15, weight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: tone,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: Text(
                        primaryText,
                        style: AppTextStyles.body(15, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
