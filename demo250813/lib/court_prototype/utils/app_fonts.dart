import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font utility class for consistent typography throughout the app
/// Provides Korean-compatible fonts using Google Fonts
class AppFonts {
  // Private constructor to prevent instantiation
  AppFonts._();
  
  /// Primary font family for Korean and English text
  /// Uses Noto Sans KR which supports all Korean characters
  static String get primaryFontFamily => GoogleFonts.notoSansKR().fontFamily!;
  
  /// Alternative font family (Pretendard-like alternative)
  /// Uses Inter which is similar to Pretendard for Latin characters
  static String get secondaryFontFamily => GoogleFonts.inter().fontFamily!;
  
  /// Get a TextStyle with the primary font family
  static TextStyle primary({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.notoSansKR(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
  
  /// Get a TextStyle with the secondary font family
  static TextStyle secondary({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
  
  /// Preset text styles for common use cases
  
  // Headers
  static TextStyle get h1 => primary(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle get h2 => primary(fontSize: 24, fontWeight: FontWeight.w700);
  static TextStyle get h3 => primary(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get h4 => primary(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle get h5 => primary(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle get h6 => primary(fontSize: 14, fontWeight: FontWeight.w600);
  
  // Body text
  static TextStyle get bodyLarge => primary(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium => primary(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall => primary(fontSize: 12, fontWeight: FontWeight.w400);
  
  // Labels and buttons
  static TextStyle get labelLarge => primary(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium => primary(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall => primary(fontSize: 12, fontWeight: FontWeight.w600);
  
  // Caption and overline
  static TextStyle get caption => primary(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get overline => primary(fontSize: 10, fontWeight: FontWeight.w500);
  
  /// Utility method to replace 'Pretendard' with Google Fonts
  /// Use this to migrate existing TextStyles
  static TextStyle replacePretendard(TextStyle style) {
    return style.copyWith(
      fontFamily: primaryFontFamily,
    );
  }
}