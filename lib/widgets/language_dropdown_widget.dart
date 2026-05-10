import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageDropdownWidget extends StatefulWidget {
  const LanguageDropdownWidget({super.key});

  @override
  State<LanguageDropdownWidget> createState() => _LanguageDropdownWidgetState();
}

class _LanguageDropdownWidgetState extends State<LanguageDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode.toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.only(right: 12), // Added padding to move it left
      child: PopupMenuButton<Locale>(
        padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withOpacity(0.08),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              currentLocale,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 18),
          ],
        ),
      ),
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
    ),);
  }
}
