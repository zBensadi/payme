import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routing/app_router.dart';
import 'presentation/features/settings/controllers/settings_controller.dart';

class PayMeApp extends ConsumerWidget {
  const PayMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PayMe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      locale: Locale(ref.watch(settingsControllerProvider).maybeWhen(data: (d) => d.languageCode, orElse: () => 'en')),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
    );
  }
}
