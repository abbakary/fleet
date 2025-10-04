import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({required SharedPreferences preferences}) : _preferences = preferences {
    final code = _preferences.getString(_storageKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
  }

  static const _storageKey = 'app_locale';

  final SharedPreferences _preferences;
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _preferences.setString(_storageKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> useSystemLocale() async {
    _locale = null;
    await _preferences.remove(_storageKey);
    notifyListeners();
  }

  bool isCurrentLocale(Locale locale) {
    return _locale?.languageCode == locale.languageCode;
  }
}
