import '../datasources/remote_backup_datasource.dart';
import 'calibration_repository.dart';
import 'reading_repository.dart';
import 'user_repository.dart';

class BackupRepository {
  BackupRepository(this._remote, this._users, this._readings, this._calibration);

  final RemoteBackupDataSource _remote;
  final UserRepository _users;
  final ReadingRepository _readings;
  final CalibrationRepository _calibration;

  bool get isAvailable => _remote.isAvailable;

  Future<void> backupNow() => _remote.upload({
    'createdAt': DateTime.now().toIso8601String(),
    'profile': _users.profile.value?.toMap(),
    'readings': _readings.readings.map((r) => r.toMap()).toList(),
    'calibration': _calibration.points.map((p) => p.toMap()).toList(),
  });
}
