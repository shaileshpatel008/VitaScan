import '../../core/constants/storage_keys.dart';
import '../../core/services/storage_service.dart';

/// Raw map access to the encrypted Hive boxes.
class LocalDataSource {
  LocalDataSource(this._storage);

  final StorageService _storage;

  Map<dynamic, dynamic>? readProfile() => _storage.profileBox.get(StorageKeys.profile) as Map?;
  Future<void> writeProfile(Map<String, dynamic> map) => _storage.profileBox.put(StorageKeys.profile, map);

  Map<dynamic, dynamic>? readSettings() => _storage.settingsBox.get(StorageKeys.settings) as Map?;
  Future<void> writeSettings(Map<String, dynamic> map) => _storage.settingsBox.put(StorageKeys.settings, map);

  List<Map<dynamic, dynamic>> readReadings() => _storage.readingsBox.values.whereType<Map>().toList();
  Future<void> writeReading(String id, Map<String, dynamic> map) => _storage.readingsBox.put(id, map);
  Future<void> deleteReading(String id) => _storage.readingsBox.delete(id);

  List<Map<dynamic, dynamic>> readCalibrations() => _storage.calibrationBox.values.whereType<Map>().toList();
  Future<void> writeCalibration(String id, Map<String, dynamic> map) => _storage.calibrationBox.put(id, map);
  Future<void> deleteCalibrationsForReading(String readingId) async {
    final keys = _storage.calibrationBox.keys
        .where((k) => (_storage.calibrationBox.get(k) as Map?)?['scanReadingId'] == readingId)
        .toList();
    await _storage.calibrationBox.deleteAll(keys);
  }

  Future<void> clearAll() => _storage.clearAll();
}
