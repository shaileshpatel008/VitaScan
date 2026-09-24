import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.foreground = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.icon,
  });

  const StatusChip.estimate({super.key, this.label = 'Estimate'})
    : foreground = AppColors.amber,
      background = AppColors.amberSoft,
      icon = null;

  const StatusChip.beta({super.key, this.label = 'Beta'})
    : foreground = AppColors.amber,
      background = AppColors.amberSoft,
      icon = null;

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
          Text(
            label,
            style: AppTextStyles.body(12, weight: FontWeight.w600, color: foreground, height: 1.2),
          ),
        ],
      ),
    );
  }
}
