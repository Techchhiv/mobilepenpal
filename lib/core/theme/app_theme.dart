import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme([String languageCode = 'en']) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      textTheme: _getTextTheme(languageCode).copyWith(
        headlineSmall: _getTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
          languageCode: languageCode,
        ),
        bodyMedium: _getTextStyle(
          fontSize: 16,
          color: AppColors.text,
          languageCode: languageCode,
        ),
      ),
    );
  }

  static ThemeData darkTheme([String languageCode = 'en']) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.black,
      ),
      textTheme: _getTextTheme(languageCode).copyWith(
        headlineSmall: _getTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
          languageCode: languageCode,
        ),
        bodyMedium: _getTextStyle(
          fontSize: 16,
          color: AppColors.darkText,
          languageCode: languageCode,
        ),
      ),
    );
  }

  static TextTheme _getTextTheme(String languageCode) {
    if (languageCode == 'km') {
      return GoogleFonts.battambangTextTheme();
    } else {
      TextTheme baseTheme = GoogleFonts.robotoTextTheme();
      return baseTheme;
    }
  }

  static TextStyle _getTextStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    required String languageCode,
  }) {
    if (languageCode == 'km') {
      return GoogleFonts.battambang(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ).copyWith(
        fontFamilyFallback: [
          GoogleFonts.battambang().fontFamily!,
        ],
      );
    }
  }
}