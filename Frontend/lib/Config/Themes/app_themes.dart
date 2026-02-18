import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark_body,
      primaryColor: AppColors.dark_navbar,
      cardColor: AppColors.dark_card,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.dark_navbar,
        foregroundColor: AppColors.dark_text,
        elevation: 0,
      ),
      
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headline1(AppColors.dark_text),
        headlineMedium: AppTextStyles.headline2(AppColors.dark_text),
        titleLarge: AppTextStyles.title(AppColors.dark_text),
        bodyMedium: AppTextStyles.bodyText(AppColors.dark_text),
        bodySmall: AppTextStyles.bodyText2(AppColors.dark_text),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark_buttons,
          foregroundColor: Colors.black,
          textStyle: AppTextStyles.buttonText(Colors.black),
        ),
      ),
      
      // cardTheme: const CardTheme(
      //   color: AppColors.dark_card,
      //   elevation: 4,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      // ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.light_body,
      primaryColor: AppColors.light_navbar,
      cardColor: AppColors.light_card,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.light_navbar,
        foregroundColor: AppColors.light_text,
        elevation: 0,
      ),
      
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headline1(AppColors.light_text),
        headlineMedium: AppTextStyles.headline2(AppColors.light_text),
        titleLarge: AppTextStyles.title(AppColors.light_text),
        bodyMedium: AppTextStyles.bodyText(AppColors.light_text),
        bodySmall: AppTextStyles.bodyText2(AppColors.light_text),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light_buttons,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonText(Colors.white),
        ),
      ),

      // cardTheme: const CardTheme(
      //   color: AppColors.light_card,
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      // ),
    );
  }
}
