import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/locale_controller.dart';
import '../utils/localization_extensions.dart';
import '../utils/app_strings.dart';

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({this.iconColor, super.key});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final localeController = context.watch<LocaleController>();
    final l10n = context.l10n;
    final currentCode = localeController.locale?.languageCode;

    return PopupMenuButton<_LanguageSelection>(
      tooltip: l10n.languageMenuTooltip,
      icon: Icon(Icons.language_outlined, color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
      onSelected: (selection) async {
        switch (selection) {
          case _LanguageSelection.system:
            await localeController.useSystemLocale();
            AppStrings.setLanguageCode(null);
          case _LanguageSelection.english:
            await localeController.setLocale(const Locale('en'));
            AppStrings.setLanguageCode('en');
          case _LanguageSelection.swahili:
            await localeController.setLocale(const Locale('sw'));
            AppStrings.setLanguageCode('sw');
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_LanguageSelection>>[
        CheckedPopupMenuItem<_LanguageSelection>(
          value: _LanguageSelection.system,
          checked: currentCode == null,
          child: Text(l10n.languageMenuSystem),
        ),
        CheckedPopupMenuItem<_LanguageSelection>(
          value: _LanguageSelection.english,
          checked: currentCode == 'en',
          child: Text(l10n.languageMenuEnglish),
        ),
        CheckedPopupMenuItem<_LanguageSelection>(
          value: _LanguageSelection.swahili,
          checked: currentCode == 'sw',
          child: Text(l10n.languageMenuSwahili),
        ),
      ],
    );
  }
}

enum _LanguageSelection { system, english, swahili }
