import 'package:flutter/material.dart';
import 'package:language_picker_with_country_flag/language_picker_with_country_flag.dart';
import 'package:language_picker_with_country_flag/languages.dart';

class LanguageViewModel extends ChangeNotifier {
  Language _selectedLanguage = languages.firstWhere(
    (l) => l.code.toLowerCase() == 'en',
    orElse: () => languages.first,
  );

  Language get selectedLanguage => _selectedLanguage;

  Locale get locale => Locale(_selectedLanguage.code);

  void changeLanguage(Language language) {
    if (_selectedLanguage.code == language.code) return;
    _selectedLanguage = language;
    notifyListeners();
  }

  // Simplified translator for now, as full Google Translator integration
  // requires more dependencies and error handling.
  // For this template, we establish the structure.
  String getText(String text) {
    // In a real app, this would check a cache or generic translator
    return text;
  }
}
