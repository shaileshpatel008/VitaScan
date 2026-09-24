import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_spacing.dart';

extension EntranceX on Widget {
  /// Staggered fade + rise used for list and card entrances.
  Widget entrance(int index, {double offset = 0.08}) =>
      animate(delay: AppDurations.stagger * index)
          .fadeIn(duration: 380.ms, curve: Curves.easeOut)
          .slideY(begin: offset, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
}
