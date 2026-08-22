import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:payme/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routing/app_router.dart';
import 'presentation/providers/locale_controller.dart';
import 'core/constants/supported_locales.dart';
import 'presentation/utils/sync_refresh_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database_provider.dart';
import 'core/database/database_service.dart';
import 'core/logging/logger_service.dart';
import 'core/providers/shared_preferences_provider.dart';

class PayMeRoot extends StatefulWidget {
  final LoggerService logger;
  final SharedPreferences prefs;
  
  const PayMeRoot({super.key, required this.logger, required this.prefs});

  static Future<void> restartApp(BuildContext context) async {
    final state = context.findAncestorStateOfType<_PayMeRootState>();
    if (state != null) {
      await state.restartApp();
    }
  }

  @override
  State<PayMeRoot> createState() => _PayMeRootState();
}

class _PayMeRootState extends State<PayMeRoot> {
  Key _scopeKey = UniqueKey();
  DatabaseService? _dbService;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final db = await DatabaseBootstrap.init(widget.logger);
    if (mounted) {
      setState(() {
        _dbService = db;
      });
    }
  }

  Future<void> restartApp() async {
    setState(() {
      _dbService = null;
      _scopeKey = UniqueKey();
    });
    await _initDatabase();
  }

  @override
  Widget build(BuildContext context) {
    if (_dbService == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ProviderScope(
      key: _scopeKey,
      overrides: [
        loggerProvider.overrideWithValue(widget.logger),
        databaseProvider.overrideWithValue(_dbService!),
        sharedPreferencesProvider.overrideWithValue(widget.prefs),
      ],
      child: const PayMeApp(),
    );
  }
}

class PlusIntent extends Intent {
  const PlusIntent();
}

class PayMeApp extends ConsumerWidget {
  const PayMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.add): const PlusIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadAdd): const PlusIntent(),
        const CharacterActivator('+'): const PlusIntent(),
      },
      child: Focus(
        autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.f5) {
                SyncRefreshHelper.refresh(ref);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                final primaryFocus = FocusManager.instance.primaryFocus;
                if (primaryFocus?.context?.widget is EditableText) {
                  return KeyEventResult.ignored;
                }
                if (goRouter.canPop()) {
                  goRouter.pop();
                  return KeyEventResult.handled;
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: MaterialApp.router(
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
      ),
    ));
  }
}
