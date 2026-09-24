import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Optional cloud backup. Only used when [ApiEndpoints.baseUrl] is set.
class RemoteBackupDataSource {
  RemoteBackupDataSource(this._client);

  final ApiClient _client;

  bool get isAvailable => ApiEndpoints.isConfigured;

  Future<void> upload(Map<String, dynamic> payload) async {
    await _client.postJson(ApiEndpoints.backupUpload, payload);
  }

  Future<Map<String, dynamic>> latest() => _client.getJson(ApiEndpoints.backupRestore);
}
