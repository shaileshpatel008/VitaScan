import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../data/models/vital_reading.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/status_chip.dart';

class ReadingTile extends StatelessWidget {
  const ReadingTile({super.key, required this.reading, required this.onTap});

  final VitalReading reading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final category = r.bpCategory;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 34,
              decoration: BoxDecoration(
                color: category?.color ?? AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: r.bpText,
                          style: AppTextStyles.body(15, weight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' mmHg',
                          style: AppTextStyles.body(12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    [r.timestamp.friendly, if (r.heartRate != null) '${r.heartRate} bpm'].join(' · '),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            r.isScan ? const StatusChip.estimate(label: 'Scan') : const StatusChip(label: 'Cuff'),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
