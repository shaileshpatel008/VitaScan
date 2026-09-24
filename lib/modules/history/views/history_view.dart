import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/segmented_selector.dart';
import '../controllers/history_controller.dart';
import '../widgets/bp_trend_chart.dart';
import '../widgets/reading_tile.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final items = c.items;
        final summary = c.summary;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 24),
          children: [
            Text('History', style: AppTextStyles.display(28)),
            const SizedBox(height: 12),
            SegmentedSelector<HistoryRange>(
              options: HistoryRange.values,
              selected: c.range.value,
              onChanged: (r) => c.range.value = r,
              labelOf: (r) => r.label,
              height: 38,
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Blood pressure', style: AppTextStyles.body(14, weight: FontWeight.w600)),
                      ),
                      const _Legend(color: AppColors.primary, label: 'Systolic'),
                      const SizedBox(width: 12),
                      const _Legend(color: AppColors.diastolic, label: 'Diastolic'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BpTrendChart(readings: c.bpSeries, range: c.range.value),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      _stat('Avg', summary.avgBp ?? '--/--'),
                      _stat('Avg HR', summary.avgHr == null ? '--' : '${summary.avgHr} bpm'),
                      Text('${summary.count} readings', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ).entrance(0),
            const SizedBox(height: 8),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.insights_rounded,
                title: AppStrings.historyEmptyTitle,
                message: AppStrings.historyEmptyBody,
                actionLabel: 'Start a scan',
                onAction: c.startScan,
              )
            else
              for (var i = 0; i < items.length; i++)
                Dismissible(
                  key: ValueKey(items[i].id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => c.confirmDelete(items[i]),
                  onDismissed: (_) => c.delete(items[i]),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.coralSoft,
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
                  ),
                  child: ReadingTile(reading: items[i], onTap: () => c.open(items[i])),
                ).entrance(i.clamp(0, 10) + 1),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Tip: swipe left on a reading to delete it.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _stat(String label, String value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$label ', style: AppTextStyles.bodySmall),
        TextSpan(
          text: value,
          style: AppTextStyles.body(13, weight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.body(12, color: AppColors.muted)),
      ],
    );
  }
}
