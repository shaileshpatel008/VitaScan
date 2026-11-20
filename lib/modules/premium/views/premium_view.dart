import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/premium_policy.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/entrance.dart';
import '../../../widgets/heartbeat.dart';
import '../controllers/premium_controller.dart';
import '../widgets/plan_card.dart';

class PremiumView extends GetView<PremiumController> {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Obx(() => c.purchases.isPremium ? _PremiumActive(c: c) : _Paywall(c: c)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16897D), AppColors.primary, Color(0xFF0A4F49)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
              PulseHalo(
                color: Colors.white,
                size: 130,
                child: Heartbeat(
                  bpm: 60,
                  amount: 0.06,
                  child: Image.asset(AppAssets.logoMark, width: 130, height: 130),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.display(27, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(15, color: Colors.white.withValues(alpha: 0.9)),
              ),
              if (trailing != null) ...[const SizedBox(height: 14), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Paywall extends StatelessWidget {
  const _Paywall({required this.c});
  final PremiumController c;

  @override
  Widget build(BuildContext context) {
    final p = c.purchases;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                title: AppStrings.premiumTitle,
                subtitle: AppStrings.premiumSubtitle,
                trailing: Obx(() {
                  final a = p.allowance;
                  final text = a.canScan
                      ? '${a.remaining} of ${a.limit} free scans left'
                      : 'You\'ve used all ${a.limit} free scans';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      text,
                      style: AppTextStyles.body(13, weight: FontWeight.w600, color: Colors.white),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 20, AppSpacing.screen, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Benefit(icon: Icons.all_inclusive_rounded, text: 'Unlimited scans, every day').entrance(0),
                    const _Benefit(icon: Icons.block_rounded, text: 'Ad-free experience').entrance(1),
                    const _Benefit(
                      icon: Icons.lock_outline_rounded,
                      text: 'Your readings stay private on your phone',
                    ).entrance(2),
                    const _Benefit(
                      icon: Icons.favorite_border_rounded,
                      text: 'Supports ongoing improvements to Wellumi',
                    ).entrance(3),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (p.loadingProducts.value && p.products.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (p.products.isEmpty) {
                        return _PlansUnavailable(
                          message: p.storeAvailable.value
                              ? AppStrings.premiumPlansUnavailable
                              : AppStrings.premiumStoreUnavailable,
                          onRetry: p.loadProducts,
                        );
                      }
                      final savings = c.yearlySavingsPercent();
                      return Column(
                        children: [
                          for (var i = 0; i < p.products.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PlanCard(
                                product: p.products[i],
                                selected: c.selected.value == p.products[i],
                                savings: p.products[i].plan == PremiumPlan.yearly ? savings : null,
                                onTap: () => c.select(p.products[i]),
                              ),
                            ).entrance(i + 2),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    Text(AppStrings.premiumSubscriptionTerms, style: AppTextStyles.caption),
                    Wrap(
                      children: [
                        TextButton(onPressed: c.openTerms, child: const Text('Terms of Use')),
                        TextButton(onPressed: c.openPrivacy, child: const Text('Privacy Policy')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 12),
            child: Obx(() {
              final sel = c.selected.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: sel?.trial != null ? 'Start free trial' : 'Continue',
                    icon: Icons.workspace_premium_rounded,
                    loading: p.purchasing.value,
                    onPressed: sel == null ? null : c.buy,
                  ),
                  TextButton(
                    onPressed: p.restoring.value ? null : p.restore,
                    child: Text(p.restoring.value ? 'Restoring…' : 'Restore purchases'),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.body(15, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PlansUnavailable extends StatelessWidget {
  const _PlansUnavailable({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(14, color: AppColors.amber),
          ),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
        ],
      ),
    );
  }
}

class _PremiumActive extends StatelessWidget {
  const _PremiumActive({required this.c});
  final PremiumController c;

  @override
  Widget build(BuildContext context) {
    final p = c.purchases;
    return Column(
      children: [
        _Header(title: 'You\'re Premium', subtitle: 'Unlimited scans are unlocked. Thank you for supporting Wellumi.'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 24, AppSpacing.screen, 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ).animate().scale(begin: const Offset(0.4, 0.4), duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${AppConstants.appName} Premium · ${p.plan.value.label}',
                          style: AppTextStyles.body(16, weight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(label: 'Start a scan', icon: Icons.monitor_heart_outlined, onPressed: c.startScan),
                if (p.plan.value.isSubscription)
                  TextButton(onPressed: p.manageSubscription, child: const Text('Manage subscription')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
