import 'package:flutter/material.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/sparkline.dart';
import '../../../widgets/status_chip.dart';

class WeeklyTrendCard extends StatelessWidget {
  const WeeklyTrendCard({
    super.key,
    required this.systolic,
    required this.trend,
    required this.calibrationCount,
    required this.lastCalibratedAt,
    this.onTap,
  });

  final List<double> systolic;
  final String trend;
  final int calibrationCount;
  final DateTime? lastCalibratedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final calibrationText = lastCalibratedAt == null
        ? 'BP not calibrated yet: add a cuff reading'
        : 'BP estimate calibrated ${_ago(lastCalibratedAt!)}';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Systolic this week', style: AppTextStyles.body(14, weight: FontWeight.w600)),
              ),
              StatusChip(
                label: trend,
                foreground: trend == 'Rising' ? AppColors.amber : AppColors.primary,
                background: trend == 'Rising' ? AppColors.amberSoft : AppColors.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Sparkline(values: systolic),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(calibrationText, style: AppTextStyles.caption)),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 30) return '$days days ago';
    return 'on ${d.shortDate}';
  }
}
