import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../data/models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/sparkline.dart';

class ReportPreviewCard extends StatelessWidget {
  const ReportPreviewCard({
    super.key,
    required this.profile,
    required this.from,
    required this.to,
    required this.summary,
    required this.trend,
  });

  final UserProfile? profile;
  final DateTime from;
  final DateTime to;
  final ReportSummary summary;
  final List<double> trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppConstants.appName} health summary',
                  style: AppTextStyles.body(14, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (profile != null) '${profile!.name} · ${profile!.age} yrs',
              '${from.fullDate} – ${to.fullDate}',
            ].join(' · '),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: AppDurations.medium,
            child: Row(
              key: ValueKey('${summary.bpText}-${summary.count}'),
              children: [
                _Stat(label: 'Avg BP', value: summary.bpText),
                const SizedBox(width: 8),
                _Stat(label: 'Avg HR', value: summary.avgHeartRate?.toString() ?? '--'),
                const SizedBox(width: 8),
                _Stat(label: 'Readings', value: '${summary.count}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Sparkline(values: trend, height: 50),
          const SizedBox(height: 8),
          Text(
            'Camera-based values are estimates. Cuff readings are marked separately.',
            style: AppTextStyles.body(11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.body(11, color: AppColors.muted)),
            Text(value, style: AppTextStyles.body(16, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
