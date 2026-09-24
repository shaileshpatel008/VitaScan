import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Fraunces (display serif) over DM Sans (body), as in the approved mockup.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color, height: 1.12);

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.45,
  }) => GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle get h1 => display(30);
  static TextStyle get h2 => display(26);
  static TextStyle get h3 => display(21);
  static TextStyle get metric => display(30);

  static TextStyle get title => body(17, weight: FontWeight.w600);
  static TextStyle get label => body(13, color: AppColors.muted, weight: FontWeight.w600);
  static TextStyle get bodyLarge => body(16, color: AppColors.muted, height: 1.5);
  static TextStyle get bodyMedium => body(15);
  static TextStyle get bodySmall => body(13, color: AppColors.muted);
  static TextStyle get caption => body(12, color: AppColors.muted);
  static TextStyle get button => body(16, weight: FontWeight.w600, color: Colors.white);
  static TextStyle get overline =>
      body(12, weight: FontWeight.w700, color: AppColors.muted).copyWith(letterSpacing: 0.8);
}
