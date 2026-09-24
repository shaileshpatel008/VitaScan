import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) developer.log(message, name: 'VitaScan');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: 'VitaScan', error: error, stackTrace: stackTrace, level: 1000);
  }
}
