import 'package:get/get.dart';

import '../utils/app_logger.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'network_info.dart';

/// Thin GetConnect wrapper with consistent error handling.
class ApiClient extends GetConnect {
  ApiClient(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  void onInit() {
    httpClient.baseUrl = ApiEndpoints.baseUrl;
    httpClient.timeout = const Duration(seconds: 20);
    httpClient.defaultContentType = 'application/json';
    httpClient.addRequestModifier<dynamic>((request) {
      request.headers['Accept'] = 'application/json';
      AppLogger.debug('→ ${request.method.toUpperCase()} ${request.url}');
      return request;
    });
    httpClient.addResponseModifier((request, response) {
      AppLogger.debug('← ${response.statusCode} ${request.url}');
      return response;
    });
    super.onInit();
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    await _ensureOnline();
    final res = await post(path, body);
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    await _ensureOnline();
    final res = await get(path);
    return _unwrap(res);
  }

  Future<void> _ensureOnline() async {
    if (!await _networkInfo.isConnected) throw ApiException.fromStatus(null, null);
  }

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    if (res.isOk && res.body is Map<String, dynamic>) return res.body as Map<String, dynamic>;
    if (res.isOk) return {'data': res.body};
    final body = res.body;
    final msg = body is Map ? body['message']?.toString() : null;
    throw ApiException.fromStatus(res.statusCode, msg);
  }
}
