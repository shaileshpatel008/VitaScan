import '../constants/app_constants.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = AppConstants.backupBaseUrl;
  static bool get isConfigured => baseUrl.isNotEmpty;

  static const String backupUpload = '/v1/backup';
  static const String backupRestore = '/v1/backup/latest';
}
