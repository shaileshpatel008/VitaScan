/// A cuff reading paired with the camera estimate taken just before it.
class CalibrationPoint {
  const CalibrationPoint({
    required this.id,
    required this.timestamp,
    required this.scanReadingId,
    required this.cuffSystolic,
    required this.cuffDiastolic,
    required this.estimatedSystolic,
    required this.estimatedDiastolic,
  });

  final String id;
  final DateTime timestamp;
  final String scanReadingId;
  final int cuffSystolic;
  final int cuffDiastolic;

  /// Uncalibrated model output of the paired scan.
  final int estimatedSystolic;
  final int estimatedDiastolic;

  int get systolicOffset => cuffSystolic - estimatedSystolic;
  int get diastolicOffset => cuffDiastolic - estimatedDiastolic;

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'scanReadingId': scanReadingId,
    'cuffSystolic': cuffSystolic,
    'cuffDiastolic': cuffDiastolic,
    'estimatedSystolic': estimatedSystolic,
    'estimatedDiastolic': estimatedDiastolic,
  };

  factory CalibrationPoint.fromMap(Map<dynamic, dynamic> map) => CalibrationPoint(
    id: map['id'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    scanReadingId: map['scanReadingId'] as String,
    cuffSystolic: (map['cuffSystolic'] as num).toInt(),
    cuffDiastolic: (map['cuffDiastolic'] as num).toInt(),
    estimatedSystolic: (map['estimatedSystolic'] as num).toInt(),
    estimatedDiastolic: (map['estimatedDiastolic'] as num).toInt(),
  );
}
