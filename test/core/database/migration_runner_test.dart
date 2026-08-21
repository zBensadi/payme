import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/constants/app_constants.dart';
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


  test('AppConstants.schemaVersion equals 16', () {
    expect(AppConstants.schemaVersion, 16);
  });

  test('V15 upgrades to V16 and adds logo_sha256 to business_settings', () async {
    // Fake the database being at v15
    await db.execute('''
      CREATE TABLE app_meta (id INTEGER PRIMARY KEY, schema_version INTEGER);
      CREATE TABLE business_settings (id INTEGER PRIMARY KEY);
    ''');
    await db.insert('app_meta', {'id': 1, 'schema_version': 15});
    
    // Apply V16
    final scriptFile = File('lib/core/database/migrations/v16_logo_sha256.sql');
    final scriptContent = await scriptFile.readAsString();
    await runner.applyMigration(db, scriptContent, 16);
    
    final tableInfo = await db.rawQuery('PRAGMA table_info(business_settings)');
    final columnNames = tableInfo.map((c) => c['name'] as String).toList();
    
    expect(columnNames, contains('logo_sha256'));
    
    final meta = await db.query('app_meta');
    expect(meta.first['schema_version'], 16);
  });

  test('V12 upgrades to V13 and creates deleted_client_visibilities', () async {
    // Fake the database being at v12
    await db.execute('''
      CREATE TABLE app_meta (id INTEGER PRIMARY KEY, schema_version INTEGER);
    ''');
    await db.insert('app_meta', {'id': 1, 'schema_version': 12});
    
    // Apply V13
    final scriptFile = File('lib/core/database/migrations/v13_client_visibility_tombstones.sql');
    final scriptContent = await scriptFile.readAsString();
    await runner.applyMigration(db, scriptContent, 13);
    
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = tables.map((t) => t['name'] as String).toList();
    
    expect(tableNames, contains('deleted_client_visibilities'));
    
    final meta = await db.query('app_meta');
    expect(meta.first['schema_version'], 13);
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
