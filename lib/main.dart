import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/logging/logger_service.dart';
import 'core/database/database_provider.dart';
import 'core/config/app_environment.dart';
import 'core/providers/shared_preferences_provider.dart';
// TEMP DEBUG INSTRUMENTATION
String _ts() => DateTime.now().toIso8601String();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP][${_ts()}][main] WidgetsFlutterBinding.ensureInitialized() done');

  debugPrint('[STARTUP][${_ts()}][main] BEFORE LoggerService.init()');
  final logger = await LoggerService.init();
  debugPrint('[STARTUP][${_ts()}][main] AFTER  LoggerService.init() → ok');

  logger.info('Application Started (Environment: ${EnvironmentConfig.currentEnvironment.name})');

  debugPrint('[STARTUP][${_ts()}][main] BEFORE Firebase.initializeApp()');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[STARTUP][${_ts()}][main] AFTER  Firebase.initializeApp() → ok');
  } catch (e, s) {
    debugPrint('[STARTUP][${_ts()}][main] ERROR  Firebase.initializeApp() threw: $e\n$s');
    rethrow;
  }

  debugPrint('[STARTUP][${_ts()}][main] BEFORE DatabaseBootstrap.init()');
  final dbService = await DatabaseBootstrap.init(logger);
  debugPrint('[STARTUP][${_ts()}][main] AFTER  DatabaseBootstrap.init() → db.isOpen=${dbService.db.isOpen}');

  debugPrint('[STARTUP][${_ts()}][main] BEFORE SharedPreferences.getInstance()');
  final prefs = await SharedPreferences.getInstance();
  debugPrint('[STARTUP][${_ts()}][main] AFTER  SharedPreferences.getInstance() → ok');

  debugPrint('[STARTUP][${_ts()}][main] Calling runApp() with ProviderScope');
  runApp(
    ProviderScope(
      overrides: [
        loggerProvider.overrideWithValue(logger),
        databaseProvider.overrideWithValue(dbService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PayMeApp(),
    ),
  );
  debugPrint('[STARTUP][${_ts()}][main] runApp() returned (frame scheduled)');
}
