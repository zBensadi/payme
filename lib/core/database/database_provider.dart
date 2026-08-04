import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../storage/app_paths.dart';
import '../logging/logger_service.dart';
import 'migration_runner.dart';
import 'database_service.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService not initialized. Overridden in main().');
});

class DatabaseBootstrap {
  static Future<DatabaseService> init(LoggerService logger) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await AppPaths.getDatabasePath();
    logger.info('Database path: $dbPath');

    final db = await openDatabase(
      dbPath,
      // We handle migrations ourselves using MigrationRunner
      version: null,
      onOpen: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    logger.info('Database Initialized');

    final migrationRunner = MigrationRunner(logger);
    await migrationRunner.runMigrations(db);

    return DatabaseService(db);
  }
}
