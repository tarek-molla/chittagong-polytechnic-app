import 'package:flutter/material.dart';
import '../core/theme_provider.dart';

class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeController.isDarkMode;

    return GestureDetector(
      onTap: () {
        if (isDark) {
          AppThemeController.setLightMode();
        } else {
          AppThemeController.setDarkMode();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          // Light mode track gets a premium soft slate instead of flat gray
          color: isDark ? const Color(0xFF0F1026) : const Color(0xFFE2E8F0),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Thumb color pops with deep indigo in light mode
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF4F46E5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
