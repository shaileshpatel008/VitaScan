import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/check_tile.dart';
import '../../../widgets/entrance.dart';
import '../controllers/reports_controller.dart';
import '../widgets/report_preview_card.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final range = c.range;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 16),
                children: [
                  Text('Reports', style: AppTextStyles.display(28)),
                  const SizedBox(height: 6),
                  Text('Create a PDF summary to share with your doctor or family.', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  ReportPreviewCard(
                    profile: c.profile,
                    from: range.start,
                    to: range.end,
                    summary: c.summary,
                    trend: c.systolicTrend,
                  ).entrance(0),
                  const SizedBox(height: 18),
                  Text('Period', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in ReportPeriod.values)
                        _PeriodChip(
                          label:
                              p == ReportPeriod.custom &&
                                  c.period.value == ReportPeriod.custom &&
                                  c.customRange.value != null
                              ? 'Custom ✓'
                              : p.label,
                          selected: c.period.value == p,
                          onTap: () => c.selectPeriod(context, p),
                        ),
                    ],
                  ).entrance(1),
                  const SizedBox(height: 12),
                  CheckTile(
                    value: c.includeCharts.value,
                    onChanged: (v) => c.includeCharts.value = v,
                    label: 'Include charts',
                  ).entrance(2),
                  CheckTile(
                    value: c.includeNotes.value,
                    onChanged: (v) => c.includeNotes.value = v,
                    label: 'Include my notes',
                  ).entrance(3),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Download PDF',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.secondary,
                      loading: c.downloading.value,
                      onPressed: c.download,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      loading: c.sharing.value,
                      onPressed: c.share,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.segment,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.body(13, weight: FontWeight.w600, color: selected ? Colors.white : AppColors.muted),
          ),
        ),
      ),
    );
  }
}
