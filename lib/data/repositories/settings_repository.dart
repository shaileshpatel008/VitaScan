import 'package:get/get.dart';

import '../datasources/local_datasource.dart';
import '../models/app_settings.dart';

class SettingsRepository extends GetxService {
  SettingsRepository(this._local);

  final LocalDataSource _local;
  late final Rx<AppSettings> settings;

  @override
  void onInit() {
    final map = _local.readSettings();
    settings = (map == null ? const AppSettings() : AppSettings.fromMap(map)).obs;
    super.onInit();
  }

  AppSettings get current => settings.value;

  Future<void> update(AppSettings Function(AppSettings) change) async {
    final next = change(settings.value);
    settings.value = next;
    await _local.writeSettings(next.toMap());
  }

  Future<void> reset() async {
    settings.value = const AppSettings();
    await _local.writeSettings(settings.value.toMap());
  }
}
