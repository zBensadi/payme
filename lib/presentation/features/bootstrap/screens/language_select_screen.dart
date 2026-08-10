import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/locale_controller.dart';
import '../../../../core/constants/supported_locales.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.language,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Select Language\nChoisissez la langue\nاختر اللغة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                ...SupportedLocales.all.map((locale) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await ref.read(localeControllerProvider.notifier).setLocale(locale.languageCode);
                          if (context.mounted) {
                            context.go('/firebase-login');
                          }
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          SupportedLocales.getLanguageName(locale.languageCode),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
