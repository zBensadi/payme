import 'package:flutter/material.dart';

class SupportedLocales {
  SupportedLocales._();

  static const english = Locale('en');
  static const french = Locale('fr');
  static const arabic = Locale('ar');

  static const all = [english, french, arabic];

  static String getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }
}
