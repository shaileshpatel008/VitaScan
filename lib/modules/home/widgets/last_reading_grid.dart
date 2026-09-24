import 'package:flutter/material.dart';

import '../../../core/utils/health_classifier.dart';
import '../../../data/models/vital_reading.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/status_chip.dart';

class LastReadingGrid extends StatelessWidget {
  const LastReadingGrid({super.key, required this.reading, this.onTap});

  final VitalReading reading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final tiles = <Widget>[
      MetricCard(
        icon: Icons.bloodtype_outlined,
        label: 'Blood pressure',
        textValue: r.bpText,
        unit: 'mmHg',
        note: r.bpCategory?.label ?? '',
        tag: r.isScan ? const StatusChip.estimate(label: 'Est.') : const StatusChip(label: 'Cuff'),
        onTap: onTap,
      ),
      MetricCard(
        icon: Icons.favorite_border_rounded,
        label: 'Heart rate',
        value: r.heartRate,
        textValue: '--',
        unit: 'bpm',
        note: r.heartRate == null ? '' : HeartRateStatus.describe(r.heartRate!),
        onTap: onTap,
      ),
      MetricCard(
        icon: Icons.speed_rounded,
        label: 'Stress',
        textValue: r.stressLevel?.label ?? '--',
        note: r.stressScore == null ? 'Scan to measure' : 'Score ${r.stressScore} / 100',
        onTap: onTap,
      ),
      MetricCard(
        icon: Icons.air_rounded,
        label: 'Breathing',
        value: r.breathingRate,
        textValue: '--',
        unit: '/min',
        note: r.breathingRate == null ? 'Scan to measure' : HeartRateStatus.breathingLabel(r.breathingRate!),
        onTap: onTap,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: tiles,
    );
  }
}
