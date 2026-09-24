import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
