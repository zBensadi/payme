import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/logging/logger_service.dart';

void main() {
  late Database db;
  late MigrationRunner runner;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final logger = Logger(level: Level.off);
    runner = MigrationRunner(LoggerService(logger));
  });

  tearDown(() async {
    await db.close();
  });

  test('MigrationRunner applies v1_initial.sql and creates expected tables', () async {
    // Load script from file system directly in tests
    final scriptFile = File('lib/core/database/migrations/v1_initial.sql');
    final scriptContent = await scriptFile.readAsString();

    await runner.applyMigration(db, scriptContent, 1);

    // Verify tables exist
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(tableNames, contains('app_meta'));
    expect(tableNames, contains('accounting_years'));
    expect(tableNames, contains('clients'));
    expect(tableNames, contains('invoices'));
    expect(tableNames, contains('payments'));
    expect(tableNames, contains('payment_attachments'));
    expect(tableNames, contains('business_settings'));
    expect(tableNames, contains('admin_credential'));

    // Verify schema version is correctly set
    final meta = await db.query('app_meta');
    expect(meta.length, 1);
    expect(meta.first['schema_version'], 1);
  });
}
