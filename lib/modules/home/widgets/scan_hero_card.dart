import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/heartbeat.dart';

class ScanHeroCard extends StatelessWidget {
  const ScanHeroCard({
    super.key,
    required this.onStart,
    required this.firstScan,
    this.statusLabel,
    this.locked = false,
  });

  final VoidCallback onStart;
  final bool firstScan;

  /// e.g. "2 free scans left" or "Premium".
  final String? statusLabel;

  /// Free scans used up: the button leads to Premium.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Heartbeat(
                  bpm: 60,
                  amount: 0.14,
                  child: Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstScan ? 'Take your first scan' : 'Take a 45-second scan',
                      style: AppTextStyles.display(21, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Best done seated, after 1 minute of rest',
                      style: AppTextStyles.body(13, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (statusLabel != null) ...[
            Row(
              children: [
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.workspace_premium_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(statusLabel!, style: AppTextStyles.body(13, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: locked ? 'Unlock unlimited scans' : 'Start scan',
            variant: AppButtonVariant.light,
            height: 48,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
