import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/storage_keys.dart';

/// Opens AES-encrypted Hive boxes. The key lives in the OS keystore/keychain.
class StorageService extends GetxService {
  late final Box<dynamic> profileBox;
  late final Box<dynamic> readingsBox;
  late final Box<dynamic> calibrationBox;
  late final Box<dynamic> settingsBox;

  Future<StorageService> init() async {
    await Hive.initFlutter();
    final cipher = HiveAesCipher(await _encryptionKey());
    profileBox = await Hive.openBox(StorageKeys.profileBox, encryptionCipher: cipher);
    readingsBox = await Hive.openBox(StorageKeys.readingsBox, encryptionCipher: cipher);
    calibrationBox = await Hive.openBox(StorageKeys.calibrationBox, encryptionCipher: cipher);
    settingsBox = await Hive.openBox(StorageKeys.settingsBox, encryptionCipher: cipher);
    return this;
  }

  Future<List<int>> _encryptionKey() async {
    const secure = FlutterSecureStorage();
    var encoded = await secure.read(key: StorageKeys.encryptionKey);
    if (encoded == null) {
      encoded = base64UrlEncode(Hive.generateSecureKey());
      await secure.write(key: StorageKeys.encryptionKey, value: encoded);
    }
    return base64Url.decode(encoded);
  }

  Future<void> clearAll() async {
    await Future.wait([profileBox.clear(), readingsBox.clear(), calibrationBox.clear(), settingsBox.clear()]);
  }
}
