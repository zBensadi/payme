import sys

file_path = "test/core/database/migration_runner_test.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

tests = """
  test('AppConstants.schemaVersion equals 13', () {
    expect(AppConstants.schemaVersion, 13);
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
"""

content = content.replace("import 'package:payme/core/database/migration_runner.dart';", "import 'package:payme/core/database/migration_runner.dart';\nimport 'package:payme/core/constants/app_constants.dart';")
content = content.replace("  test('MigrationRunner applies v1_initial.sql", tests + "\n  test('MigrationRunner applies v1_initial.sql")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

