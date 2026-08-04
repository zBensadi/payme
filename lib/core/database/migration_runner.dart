import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../logging/logger_service.dart';

class MigrationRunner {
  final LoggerService _logger;

  MigrationRunner(this._logger);

  Future<void> runMigrations(Database db) async {
    // Check if app_meta table exists
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'app_meta'],
    );

    int currentVersion = 0;
    if (tables.isNotEmpty) {
      final meta = await db.query('app_meta', limit: 1);
      if (meta.isNotEmpty) {
        currentVersion = meta.first['schema_version'] as int;
      }
    }

    _logger.info('Database current schema version: $currentVersion. Expected: ${AppConstants.schemaVersion}');

    if (currentVersion > AppConstants.schemaVersion) {
      _logger.error('Database schema is newer than the app expects.');
      throw Exception('Database schema version is newer than the app supports. Please update the app.');
    }

    if (currentVersion < AppConstants.schemaVersion) {
      if (currentVersion == 0) {
        _logger.info('Running migration: v1_initial.sql');
        final scriptContent = await loadMigrationScript('v1_initial.sql');
        await applyMigration(db, scriptContent, 1);
        currentVersion = 1;
      }
      if (currentVersion == 1) {
        _logger.info('Running migration: v2_invoice_sequence.sql');
        final scriptContent = await loadMigrationScript('v2_invoice_sequence.sql');
        await applyMigration(db, scriptContent, 2);
        currentVersion = 2;
      }
      if (currentVersion == 2) {
        _logger.info('Running migration: v3_add_language.sql');
        final scriptContent = await loadMigrationScript('v3_add_language.sql');
        await applyMigration(db, scriptContent, 3);
        currentVersion = 3;
      }
    }
  }

  Future<String> loadMigrationScript(String scriptName) async {
    return await rootBundle.loadString('lib/core/database/migrations/$scriptName');
  }

  Future<void> applyMigration(Database db, String scriptContent, int targetVersion) async {
    final statements = scriptContent
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    await db.transaction((txn) async {
      for (final statement in statements) {
        await txn.execute(statement);
      }
      
      if (targetVersion == 1) {
        await txn.insert('app_meta', {'id': 1, 'schema_version': targetVersion});
      } else {
        await txn.update('app_meta', {'schema_version': targetVersion}, where: 'id = 1');
      }
    });

    _logger.info('Migration applied successfully. Now at version $targetVersion');
  }
}
