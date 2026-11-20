import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/entrance.dart';
import '../controllers/home_controller.dart';
import '../widgets/last_reading_grid.dart';
import '../widgets/scan_hero_card.dart';
import '../widgets/tip_card.dart';
import '../widgets/weekly_trend_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final latest = c.latest;
        final week = c.weekBp;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateTime.now().greeting, style: AppTextStyles.bodySmall),
                      Text(c.profile?.firstName ?? 'there', style: AppTextStyles.h2),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reminders',
                  onPressed: c.openReminders,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.ink),
                ),
              ],
            ).entrance(0),
            const SizedBox(height: 16),
            ScanHeroCard(
              onStart: c.startScan,
              firstScan: latest == null,
              statusLabel: c.scanStatus,
              locked: !c.allowance.canScan,
            ).entrance(1),
            const SizedBox(height: 18),
            if (latest == null)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your readings will appear here after your first scan. It only takes 45 seconds.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ).entrance(2)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Last reading · ${latest.timestamp.friendly}',
                      style: AppTextStyles.body(15, weight: FontWeight.w600),
                    ),
                  ),
                  TextButton(onPressed: c.openLatest, child: const Text('View')),
                ],
              ).entrance(2),
              const SizedBox(height: 4),
              LastReadingGrid(reading: latest, onTap: c.openLatest).entrance(3),
              const SizedBox(height: 12),
              WeeklyTrendCard(
                systolic: week.map((r) => r.systolic!.toDouble()).toList(),
                trend: c.trendLabel,
                calibrationCount: c.calibrationCount,
                lastCalibratedAt: c.lastCalibratedAt,
                onTap: c.openHistory,
              ).entrance(4),
            ],
            const SizedBox(height: 12),
            Obx(() => TipCard(tip: HomeController.tips[c.tipIndex.value])).entrance(5),
          ],
        );
      }),
    );
  }
}
