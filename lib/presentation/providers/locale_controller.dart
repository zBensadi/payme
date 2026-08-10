import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/shared_preferences_provider.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  static const _localeKey = 'ui_language_code';

  @override
  Locale? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_localeKey);
    if (code != null) {
      return Locale(code);
    }
    return null;
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
  }
}
