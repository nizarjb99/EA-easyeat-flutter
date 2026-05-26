import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../utils/styles.dart';

class LanguageDropdownWidget extends StatefulWidget {
  const LanguageDropdownWidget({super.key});

  @override
  State<LanguageDropdownWidget> createState() => _LanguageDropdownWidgetState();
}

class _LanguageDropdownWidgetState extends State<LanguageDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.glassBg : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.text : AppColors.authText;
    final mutedColor = isDark ? AppColors.textMuted : AppColors.authTextMuted;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<Locale>(
        padding: EdgeInsets.zero,
        onSelected: (Locale locale) async {
          await context.setLocale(locale);
          if (mounted) {
            setState(() {});
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            const PopupMenuItem(
              value: Locale('en'),
              child: Text('EN - English'),
            ),
            const PopupMenuItem(
              value: Locale('es'),
              child: Text('ES - Español'),
            ),
            const PopupMenuItem(
              value: Locale('ca'),
              child: Text('CA - Català'),
            ),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: backgroundColor,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                currentLocale,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: mutedColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
