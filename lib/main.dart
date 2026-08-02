import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/logging/logger_service.dart';
import 'core/database/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = await LoggerService.init();
  logger.info('Application Started');
  
  final dbService = await DatabaseBootstrap.init(logger);
  
  runApp(
    ProviderScope(
      overrides: [
        loggerProvider.overrideWithValue(logger),
        databaseProvider.overrideWithValue(dbService),
      ],
      child: const PayMeApp(),
    ),
  );
}
