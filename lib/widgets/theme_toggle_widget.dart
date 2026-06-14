import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/styles.dart';

class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final brightnessIsDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = brightnessIsDark ? AppColors.glassBg : Colors.white;
    final borderColor = brightnessIsDark
        ? AppColors.glassBorder
        : const Color(0xFFE2E8F0);
    final iconColor = brightnessIsDark ? AppColors.text : AppColors.authText;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: isDark ? 'Light mode' : 'Dark mode',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: themeProvider.toggleTheme,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: backgroundColor,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
