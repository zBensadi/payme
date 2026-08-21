import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/logging/logger_service.dart';
import 'core/config/app_environment.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = await LoggerService.init();
  logger.info('Application Started (Environment: ${EnvironmentConfig.currentEnvironment.name})');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  
  // Existing session persistence is handled automatically by Firebase Auth.
  
  runApp(PayMeRoot(logger: logger, prefs: prefs));
}

