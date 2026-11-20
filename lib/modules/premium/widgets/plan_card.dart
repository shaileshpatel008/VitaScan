import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/premium_policy.dart';
import '../../../data/models/store_product.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.product, required this.selected, required this.onTap, this.savings});

  final StoreProduct product;
  final bool selected;
  final VoidCallback onTap;
  final int? savings;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final title = switch (p.plan) {
      PremiumPlan.yearly => 'Yearly',
      PremiumPlan.monthly => 'Monthly',
      PremiumPlan.lifetime => 'Lifetime',
      PremiumPlan.none => p.details.title,
    };
    final subtitle = p.plan == PremiumPlan.lifetime
        ? 'Pay once, keep Premium forever'
        : [if (p.trial != null) p.trial!, 'then ${p.price} / ${p.period}'].join(', ');

    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, ${p.price}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.primary : AppColors.muted, width: 2),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: AppTextStyles.body(16, weight: FontWeight.w700)),
                        if (p.plan == PremiumPlan.yearly) _Badge(label: 'Best value', color: AppColors.primary),
                        if (savings != null) _Badge(label: 'Save $savings%', color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p.price, style: AppTextStyles.body(17, weight: FontWeight.w700)),
                  if (p.period.isNotEmpty) Text('per ${p.period}', style: AppTextStyles.caption),
                  if (p.period.isEmpty) Text('one-time', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: AppTextStyles.body(11, weight: FontWeight.w700, color: Colors.white, height: 1.4),
      ),
    );
  }
}
