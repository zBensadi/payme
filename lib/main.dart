import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/logging/logger_service.dart';
import 'core/database/database_provider.dart';
import 'core/config/app_environment.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = await LoggerService.init();
  logger.info('Application Started (Environment: ${EnvironmentConfig.currentEnvironment.name})');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final dbService = await DatabaseBootstrap.init(logger);
  final prefs = await SharedPreferences.getInstance();
  
  // Existing session persistence is handled automatically by Firebase Auth.
  
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
}
