import '../../core/utils/health_classifier.dart';

enum ReadingSource {
  scan('Scan'),
  cuff('Cuff');

  const ReadingSource(this.label);
  final String label;

  static ReadingSource fromName(String? name) =>
      ReadingSource.values.firstWhere((s) => s.name == name, orElse: () => ReadingSource.scan);
}

/// One saved measurement: either a camera scan or a manually entered cuff reading.
class VitalReading {
  const VitalReading({
    required this.id,
    required this.timestamp,
    required this.source,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.hrvRmssd,
    this.stressScore,
    this.breathingRate,
    this.spo2,
    this.signalQuality,
    this.rawSystolic,
    this.rawDiastolic,
    this.isCalibrated = false,
    this.note,
  });

  final String id;
  final DateTime timestamp;
  final ReadingSource source;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final double? hrvRmssd;
  final int? stressScore;
  final int? breathingRate;
  final int? spo2;
  final int? signalQuality;

  /// Model output before personal calibration (scan readings only).
  final int? rawSystolic;
  final int? rawDiastolic;
  final bool isCalibrated;
  final String? note;

  bool get isScan => source == ReadingSource.scan;
  bool get hasBp => systolic != null && diastolic != null;
  String get bpText => hasBp ? '$systolic/$diastolic' : '--/--';

  BpCategory? get bpCategory => hasBp ? BpCategory.classify(systolic!, diastolic!) : null;
  StressLevel? get stressLevel => stressScore == null ? null : StressLevel.fromScore(stressScore!);

  VitalReading copyWith({String? note}) => VitalReading(
    id: id,
    timestamp: timestamp,
    source: source,
    systolic: systolic,
    diastolic: diastolic,
    heartRate: heartRate,
    hrvRmssd: hrvRmssd,
    stressScore: stressScore,
    breathingRate: breathingRate,
    spo2: spo2,
    signalQuality: signalQuality,
    rawSystolic: rawSystolic,
    rawDiastolic: rawDiastolic,
    isCalibrated: isCalibrated,
    note: note ?? this.note,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'source': source.name,
    'systolic': systolic,
    'diastolic': diastolic,
    'heartRate': heartRate,
    'hrvRmssd': hrvRmssd,
    'stressScore': stressScore,
    'breathingRate': breathingRate,
    'spo2': spo2,
    'signalQuality': signalQuality,
    'rawSystolic': rawSystolic,
    'rawDiastolic': rawDiastolic,
    'isCalibrated': isCalibrated,
    'note': note,
  };

  factory VitalReading.fromMap(Map<dynamic, dynamic> map) => VitalReading(
    id: map['id'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    source: ReadingSource.fromName(map['source'] as String?),
    systolic: (map['systolic'] as num?)?.toInt(),
    diastolic: (map['diastolic'] as num?)?.toInt(),
    heartRate: (map['heartRate'] as num?)?.toInt(),
    hrvRmssd: (map['hrvRmssd'] as num?)?.toDouble(),
    stressScore: (map['stressScore'] as num?)?.toInt(),
    breathingRate: (map['breathingRate'] as num?)?.toInt(),
    spo2: (map['spo2'] as num?)?.toInt(),
    signalQuality: (map['signalQuality'] as num?)?.toInt(),
    rawSystolic: (map['rawSystolic'] as num?)?.toInt(),
    rawDiastolic: (map['rawDiastolic'] as num?)?.toInt(),
    isCalibrated: map['isCalibrated'] as bool? ?? false,
    note: map['note'] as String?,
  );
}
