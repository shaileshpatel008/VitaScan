import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/utils/health_classifier.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/status_chip.dart';
import '../controllers/result_controller.dart';
import '../widgets/bp_hero_card.dart';
import '../widgets/scan_complete_banner.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return PopScope(
      canPop: !c.isFresh,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.done();
      },
      child: Scaffold(
        body: SafeArea(
          child: Obx(() {
            final r = c.reading.value;
            if (r == null) return const SizedBox.shrink();
            final metrics = <Widget>[
              if (r.heartRate != null)
                MetricCard(
                  icon: Icons.favorite_border_rounded,
                  label: r.isScan ? 'Heart rate' : 'Pulse',
                  value: r.heartRate,
                  unit: 'bpm',
                  note: HeartRateStatus.describe(r.heartRate!),
                ),
              if (r.hrvRmssd != null)
                MetricCard(
                  icon: Icons.ssid_chart_rounded,
                  label: 'HRV',
                  value: r.hrvRmssd!.round(),
                  unit: 'ms',
                  note: HeartRateStatus.hrvLabel(r.hrvRmssd!),
                ),
              if (r.stressScore != null)
                MetricCard(
                  icon: Icons.speed_rounded,
                  label: 'Stress',
                  textValue: r.stressLevel!.label,
                  note: 'Score ${r.stressScore} / 100',
                ),
              if (r.breathingRate != null)
                MetricCard(
                  icon: Icons.air_rounded,
                  label: 'Breathing',
                  value: r.breathingRate,
                  unit: '/min',
                  note: HeartRateStatus.breathingLabel(r.breathingRate!),
                ),
            ];

            return Column(
              children: [
                AppTopBar(
                  title: r.isScan ? 'Your results' : 'Cuff reading',
                  onBack: c.done,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(tooltip: 'Share', onPressed: c.share, icon: const Icon(Icons.ios_share_rounded)),
                      if (!c.isFresh)
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: c.delete,
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 4, AppSpacing.screen, 16),
                    children: [
                      if (c.isFresh) ...[const ScanCompleteBanner(), const SizedBox(height: 12)],
                      Text(
                        [
                          r.timestamp.friendly,
                          if (r.signalQuality != null) 'Signal quality ${r.signalQuality}%',
                        ].join(' · '),
                        style: AppTextStyles.bodySmall,
                      ).entrance(0),
                      const SizedBox(height: 12),
                      if (r.hasBp) BpHeroCard(reading: r).entrance(1),
                      if (metrics.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.45,
                          children: [for (var i = 0; i < metrics.length; i++) metrics[i].entrance(2 + i)],
                        ),
                      ],
                      if (r.spo2 != null) ...[
                        const SizedBox(height: 10),
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('Oxygen (SpO₂)', style: AppTextStyles.body(14, weight: FontWeight.w600)),
                              ),
                              Text('~${r.spo2}%', style: AppTextStyles.display(20)),
                              const SizedBox(width: 8),
                              const StatusChip.beta(),
                            ],
                          ),
                        ).entrance(6),
                      ],
                      if (r.note != null && r.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AppCard(child: Text(r.note!, style: AppTextStyles.bodySmall)).entrance(7),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        r.isScan ? AppStrings.disclaimerShort : 'Entered manually from a blood pressure cuff.',
                        style: AppTextStyles.caption,
                      ).entrance(7),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
                  child: Row(
                    children: [
                      if (c.canCalibrate) ...[
                        Expanded(
                          child: AppButton(
                            label: 'Calibrate BP',
                            icon: Icons.track_changes_rounded,
                            variant: AppButtonVariant.secondary,
                            onPressed: c.calibrate,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: AppButton(label: 'Done', icon: Icons.check_rounded, onPressed: c.done),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
