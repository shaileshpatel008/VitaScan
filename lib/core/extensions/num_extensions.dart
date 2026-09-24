import 'package:flutter/widgets.dart';

extension NumX on num {
  SizedBox get vSpace => SizedBox(height: toDouble());
  SizedBox get hSpace => SizedBox(width: toDouble());
}

extension NullableIntX on int? {
  String orDash([String dash = '--']) => this?.toString() ?? dash;
}
