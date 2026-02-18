import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Config/Language/language_view_model.dart';

class Translate {
  static String get(BuildContext context, String text, {bool listen = false}) {
    // Safely access LanguageViewModel
    try {
      final langVM = Provider.of<LanguageViewModel>(context, listen: listen);
      return langVM.getText(text);
    } catch (e) {
      return text;
    }
  }
}
