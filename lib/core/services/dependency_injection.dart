import 'package:get/get.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/remote_backup_datasource.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/calibration_repository.dart';
import '../../data/repositories/reading_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import 'app_update_service.dart';
import 'export_service.dart';
import 'health_sync_service.dart';
import 'notification_service.dart';
import 'pdf_report_service.dart';
import 'permission_service.dart';
import 'storage_service.dart';

/// App-wide singletons, registered once before `runApp`.
class DependencyInjection {
  DependencyInjection._();

  static Future<void> init() async {
    final storage = await Get.putAsync(() => StorageService().init(), permanent: true);
    final local = Get.put(LocalDataSource(storage), permanent: true);

    final network = Get.put(NetworkInfo(), permanent: true);
    final api = Get.put(ApiClient(network), permanent: true);
    final remote = Get.put(RemoteBackupDataSource(api), permanent: true);

    Get.put(SettingsRepository(local), permanent: true);
    final users = Get.put(UserRepository(local), permanent: true);
    final calibration = Get.put(CalibrationRepository(local), permanent: true);
    final readings = Get.put(ReadingRepository(local), permanent: true);
    Get.put(BackupRepository(remote, users, readings, calibration), permanent: true);

    Get.put(PermissionService(), permanent: true);
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    Get.put(HealthSyncService(), permanent: true);
    Get.put(PdfReportService(), permanent: true);
    Get.put(ExportService(), permanent: true);
    await Get.putAsync(() => AppUpdateService(local).init(), permanent: true);
  }
}
