import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../data/models/vital_reading.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/step_progress.dart';

class CalibrationStatusCard extends StatelessWidget {
  const CalibrationStatusCard({
    super.key,
    required this.done,
    required this.target,
    required this.linkedScan,
    required this.active,
  });

  final int done;
  final int target;
  final VitalReading? linkedScan;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final complete = done >= target;
    final String message;
    if (complete) {
      message = 'Calibrated. New cuff readings keep it up to date.';
    } else if (linkedScan != null) {
      message =
          'Add ${target - done} more reading${target - done == 1 ? '' : 's'}, taken within 10 minutes of a scan, to finish calibration.';
    } else {
      message = 'Take a scan first, then enter your cuff reading within 10 minutes to calibrate.';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Calibration', style: AppTextStyles.body(14, weight: FontWeight.w600)),
              ),
              Text(
                complete ? 'Complete' : '${done.clamp(0, target)} of $target readings',
                style: AppTextStyles.body(
                  13,
                  color: complete ? AppColors.success : AppColors.muted,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StepProgress(total: target, done: done.clamp(0, target)),
          const SizedBox(height: 10),
          Text(message, style: AppTextStyles.caption),
          if (linkedScan != null) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: active ? AppColors.primarySoft : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 18, color: active ? AppColors.primary : AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Linked scan: ${linkedScan!.timestamp.friendly} · ${linkedScan!.bpText} est.',
                      style: AppTextStyles.body(13, color: active ? AppColors.primaryDark : AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
