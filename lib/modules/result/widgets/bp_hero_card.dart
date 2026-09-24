import 'package:flutter/material.dart';

import '../../../data/models/vital_reading.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/animated_counter.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/status_chip.dart';
import 'bp_range_bar.dart';

class BpHeroCard extends StatelessWidget {
  const BpHeroCard({super.key, required this.reading});

  final VitalReading reading;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final category = r.bpCategory!;
    final big = AppTextStyles.display(46).copyWith(height: 1);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bloodtype_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Blood pressure',
                  style: AppTextStyles.body(14, weight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
              if (r.isScan) const StatusChip.estimate() else const StatusChip(label: 'Cuff reading'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCounter(value: r.systolic!, style: big),
              Text('/', style: big),
              AnimatedCounter(value: r.diastolic!, style: big),
              const SizedBox(width: 6),
              Text('mmHg', style: AppTextStyles.body(14, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(category.description, style: AppTextStyles.body(14, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          BpRangeBar(systolic: r.systolic!),
          if (r.isScan && !r.isCalibrated) ...[
            const SizedBox(height: 12),
            Text(
              'Not yet calibrated. Adding a cuff reading makes this estimate more personal.',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}
