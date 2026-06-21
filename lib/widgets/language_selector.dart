import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Color(0xFF64748B)),
      onSelected: (Locale locale) {
        context.setLocale(locale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('es'),
          child: Text('Español'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('ca'),
          child: Text('Català'),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Text('English'),
        ),
      ],
    );
  }
}
