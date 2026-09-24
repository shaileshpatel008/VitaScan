import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';
import 'heartbeat.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseHalo(
            color: AppColors.primary,
            size: 110,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: AppButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
    );
  }
}
