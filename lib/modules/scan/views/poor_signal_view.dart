import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/ppg/ppg_models.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/entrance.dart';
import '../models/scan_failure_info.dart';

class PoorSignalView extends StatelessWidget {
  const PoorSignalView({super.key});

  void _home() => Get.until((r) => r.settings.name == AppRoutes.main || r.isFirst);

  @override
  Widget build(BuildContext context) {
    final info = ScanFailureInfo.of(Get.arguments as ScanFailureReason?);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: 'Scan interrupted', onBack: _home),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.amberSoft,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(info.icon, size: 34, color: AppColors.amber),
                            )
                            .animate()
                            .scale(begin: const Offset(0.6, 0.6), duration: 400.ms, curve: Curves.easeOutBack)
                            .then()
                            .shake(hz: 3, rotation: 0.04, duration: 500.ms),
                  ),
                  const SizedBox(height: 18),
                  Text(info.title, style: AppTextStyles.display(28)).entrance(1),
                  const SizedBox(height: 8),
                  Text(
                    '${info.reason} Don\'t worry: try these, then scan again:',
                    style: AppTextStyles.bodyLarge,
                  ).entrance(2),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < info.tips.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i == info.tips.length - 1 ? 0 : 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(info.tips[i], style: AppTextStyles.body(14))),
                              ],
                            ),
                          ).entrance(3 + i),
                      ],
                    ),
                  ).entrance(3),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 16),
              child: Column(
                children: [
                  AppButton(
                    label: AppStrings.tryAgain,
                    icon: Icons.refresh_rounded,
                    onPressed: () => Get.offNamed(AppRoutes.scan),
                  ),
                  const SizedBox(height: 8),
                  AppButton(label: AppStrings.backToHome, variant: AppButtonVariant.ghost, onPressed: _home),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
