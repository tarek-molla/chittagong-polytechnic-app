import 'package:flutter/material.dart';
import 'colors.dart';

class AppThemeController {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void setLightMode() {
    themeModeNotifier.value = ThemeMode.light;
  }

  static void setDarkMode() {
    themeModeNotifier.value = ThemeMode.dark;
  }

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.lightPrimaryText),
      displayMedium: TextStyle(color: AppColors.lightPrimaryText),
      displaySmall: TextStyle(color: AppColors.lightPrimaryText),
      headlineLarge: TextStyle(color: AppColors.lightPrimaryText),
      headlineMedium: TextStyle(color: AppColors.lightPrimaryText),
      headlineSmall: TextStyle(color: AppColors.lightPrimaryText),
      titleLarge: TextStyle(color: AppColors.lightPrimaryText),
      titleMedium: TextStyle(color: AppColors.lightSubtitleText),
      titleSmall: TextStyle(color: AppColors.lightCaptionText),
      bodyLarge: TextStyle(color: AppColors.lightPrimaryText),
      bodyMedium: TextStyle(color: AppColors.lightSubtitleText),
      bodySmall: TextStyle(color: AppColors.lightCaptionText),
      labelLarge: TextStyle(color: AppColors.lightPrimaryText),
      labelMedium: TextStyle(color: AppColors.lightSubtitleText),
      labelSmall: TextStyle(color: AppColors.lightCaptionText),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightCardBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.lightCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accentColor),
      ),
      labelStyle: const TextStyle(color: AppColors.lightSubtitleText),
      hintStyle: TextStyle(color: AppColors.lightCaptionText.withOpacity(0.6)),
    ),
  );

  // ✅ Add darkTheme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF070B19),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white70),
      titleSmall: TextStyle(color: Colors.white54),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
      labelLarge: TextStyle(color: Colors.white),
      labelMedium: TextStyle(color: Colors.white70),
      labelSmall: TextStyle(color: Colors.white54),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0891B2)),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),
  );
}
