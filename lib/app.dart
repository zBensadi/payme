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
import 'presentation/utils/plus_action.dart';
import 'presentation/utils/plus_action_registry.dart';

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

// [PLUS-KEY-DIAGNOSTIC] named handler function so we can remove it in dispose
bool _plusDiagnosticHandler(KeyEvent event) {
  if (event is KeyDownEvent) {
    final lk = event.logicalKey;
    if (lk == LogicalKeyboardKey.equal ||
        lk == LogicalKeyboardKey.add ||
        lk == LogicalKeyboardKey.numpadAdd ||
        (event.character != null && event.character == '+')) {
      debugPrint(
        '[PLUS-KEY-DIAGNOSTIC][HWKeyboard] '
        'logicalKey=${event.logicalKey.keyLabel}(${event.logicalKey.keyId}) '
        'physicalKey=${event.physicalKey.usbHidUsage} '
        'character=${event.character?.isEmpty == true ? "<empty>" : event.character} '
        'synthesized=${event.synthesized} '
        'modifiers=${HardwareKeyboard.instance.logicalKeysPressed}',
      );
    }
  }
  return false; // never consume — diagnostic only
}

class PayMeApp extends ConsumerStatefulWidget {
  const PayMeApp({super.key});

  @override
  ConsumerState<PayMeApp> createState() => _PayMeAppState();
}

class _PayMeAppState extends ConsumerState<PayMeApp> {
  @override
  void initState() {
    super.initState();
    // [PLUS-KEY-DIAGNOSTIC] Step 0 — registered once, removed in dispose
    HardwareKeyboard.instance.addHandler(_plusDiagnosticHandler);
    debugPrint('[PLUS-KEY-DIAGNOSTIC][initState] HardwareKeyboard handler registered');
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_plusDiagnosticHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    final plusRegistry = ref.watch(plusActionRegistryProvider);

    return Actions(
      actions: <Type, Action<Intent>>{
        PlusIntent: PlusAction(plusRegistry),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.equal, shift: true): const PlusIntent(),
          const SingleActivator(LogicalKeyboardKey.add): const PlusIntent(),
          const SingleActivator(LogicalKeyboardKey.numpadAdd): const PlusIntent(),
          const CharacterActivator('+'): const PlusIntent(),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              // [PLUS-KEY-DIAGNOSTIC] Step 1 — root Focus.onKeyEvent sees this event
              debugPrint(
                '[PLUS-KEY-DIAGNOSTIC][Focus.onKeyEvent] '
                'logicalKey=\${event.logicalKey.keyLabel}(\${event.logicalKey.keyId}) '
                'physicalKey=\${event.physicalKey.usbHidUsage} '
                'character="\${event.character}" '
                'synthesized=\${event.synthesized} '
                'modifiers=\${HardwareKeyboard.instance.logicalKeysPressed}',
              );

              if (event.logicalKey == LogicalKeyboardKey.f5) {
                SyncRefreshHelper.refresh(ref);
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.escape) {
                final primaryFocus = FocusManager.instance.primaryFocus;
                if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
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
        ),
      ),
    );
  }
}
