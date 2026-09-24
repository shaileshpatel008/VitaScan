import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Pill-style segmented control with a sliding thumb.
class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.height = 44,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = options.indexOf(selected).clamp(0, options.length - 1);
    return Container(
      height: height + 8,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.segment, borderRadius: BorderRadius.circular(AppRadius.input)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: o == selected,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (o == selected) return;
                            HapticFeedback.selectionClick();
                            onChanged(o);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppDurations.fast,
                              style: AppTextStyles.body(
                                14,
                                weight: FontWeight.w600,
                                color: o == selected ? AppColors.ink : AppColors.muted,
                              ),
                              child: Text(labelOf(o)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
