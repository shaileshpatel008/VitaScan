import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'animated_counter.dart';
import 'app_card.dart';

/// Small vital tile: icon + label, big animated value, short note.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.textValue,
    this.unit = '',
    this.note = '',
    this.tag,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Numeric values count up; use [textValue] for words ("Low") or "118/76".
  final num? value;
  final String? textValue;
  final String unit;
  final String note;
  final Widget? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTextStyles.metric;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: AppTextStyles.label, overflow: TextOverflow.ellipsis),
              ),
              ?tag,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: value != null
                      ? AnimatedCounter(value: value!, style: valueStyle)
                      : Text(textValue ?? '--', style: valueStyle),
                ),
              ),
              if (unit.isNotEmpty) ...[const SizedBox(width: 4), Text(unit, style: AppTextStyles.bodySmall)],
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
