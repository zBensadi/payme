import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routing/app_router.dart';
import 'presentation/providers/locale_controller.dart';
import 'core/constants/supported_locales.dart';

class PayMeApp extends ConsumerWidget {
  const PayMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: 'PayMe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SupportedLocales.all,
    );
  }
}
