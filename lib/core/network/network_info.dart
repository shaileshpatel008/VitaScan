import 'dart:io';

class NetworkInfo {
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
