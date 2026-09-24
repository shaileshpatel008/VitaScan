import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';
import '../utils/app_logger.dart';

/// Opens AES-encrypted Hive boxes. The key lives in the OS keystore/keychain.
class StorageService extends GetxService {
  late Box<dynamic> profileBox;
  late Box<dynamic> readingsBox;
  late Box<dynamic> calibrationBox;
  late Box<dynamic> settingsBox;

  static const _secure = FlutterSecureStorage();
  static const _boxNames = [
    StorageKeys.profileBox,
    StorageKeys.readingsBox,
    StorageKeys.calibrationBox,
    StorageKeys.settingsBox,
  ];

  Future<StorageService> init() async {
    await Hive.initFlutter();
    try {
      await _open(await _encryptionKey());
    } catch (e, st) {
      // Key or boxes unreadable (e.g. keystore reset, or a restored backup whose
      // key no longer matches). Start fresh instead of blocking app start-up.
      AppLogger.error('Encrypted storage unreadable, resetting', e, st);
      await Hive.close();
      for (final name in _boxNames) {
        await Hive.deleteBoxFromDisk(name);
      }
      try {
        await _secure.deleteAll();
      } catch (_) {}
      await _open(await _encryptionKey());
    }
    return this;
  }

  Future<void> _open(List<int> key) async {
    final cipher = HiveAesCipher(key);
    profileBox = await Hive.openBox(StorageKeys.profileBox, encryptionCipher: cipher);
    readingsBox = await Hive.openBox(StorageKeys.readingsBox, encryptionCipher: cipher);
    calibrationBox = await Hive.openBox(StorageKeys.calibrationBox, encryptionCipher: cipher);
    settingsBox = await Hive.openBox(StorageKeys.settingsBox, encryptionCipher: cipher);
  }

  Future<List<int>> _encryptionKey() async {
    String? encoded;
    try {
      encoded = await _secure.read(key: StorageKeys.encryptionKey);
    } catch (e) {
      AppLogger.error('Secure key unreadable, regenerating', e);
      try {
        await _secure.deleteAll();
      } catch (_) {}
    }
    if (encoded == null) {
      encoded = base64UrlEncode(Hive.generateSecureKey());
      await _secure.write(key: StorageKeys.encryptionKey, value: encoded);
    }
    return base64Url.decode(encoded);
  }

  Future<void> clearAll() async {
    await Future.wait([profileBox.clear(), readingsBox.clear(), calibrationBox.clear(), settingsBox.clear()]);
  }
}
