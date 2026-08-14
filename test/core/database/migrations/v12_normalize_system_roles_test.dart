import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    
    // Create base tables needed for migration testing
    await db.execute('''
      CREATE TABLE roles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        priority INTEGER NOT NULL,
        is_system_role INTEGER NOT NULL,
        is_editable INTEGER NOT NULL,
        is_deletable INTEGER NOT NULL,
        permissions TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT,
        business_id TEXT NOT NULL,
        role_id TEXT NOT NULL,
        is_super_admin INTEGER NOT NULL DEFAULT 0,
        is_owner INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> runMigration() async {
    final file = File('lib/core/database/migrations/v12_normalize_system_roles.sql');
    final scriptContent = await file.readAsString();
    final statements = scriptContent
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    for (final stmt in statements) {
      await db.execute(stmt);
    }
  }

  test('v12 migration migrates legacy Owner and Super Admin roles to role-owner', () async {
    // Insert legacy Super Admin
    await db.insert('roles', {
      'id': 'role-super-admin',
      'name': 'Super Admin',
      'priority': 0,
      'is_system_role': 1,
      'is_editable': 0,
      'is_deletable': 0,
      'permissions': '[]',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_dirty': 0,
    });

    // Insert legacy dynamic Owner
    await db.insert('roles', {
      'id': 'dynamic-owner-id-123',
      'name': 'Owner',
      'priority': 0,
      'is_system_role': 1,
      'is_editable': 0,
      'is_deletable': 0,
      'permissions': '[]',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_dirty': 0,
    });

    // Insert users referencing legacy roles
    await db.insert('users', {
      'uid': 'user-super-admin',
      'email': 'super@test.com',
      'business_id': 'biz-1',
      'role_id': 'role-super-admin',
      'is_owner': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('users', {
      'uid': 'user-dynamic-owner',
      'email': 'owner@test.com',
      'business_id': 'biz-1',
      'role_id': 'dynamic-owner-id-123',
      'is_owner': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Run Migration
    await runMigration();

    // Verify role-owner is created and configured correctly
    final roleOwnerResult = await db.query('roles', where: 'id = ?', whereArgs: ['role-owner']);
    expect(roleOwnerResult.length, 1);
    expect(roleOwnerResult.first['priority'], 1000);
    expect(roleOwnerResult.first['is_editable'], 0);
    expect(roleOwnerResult.first['is_system_role'], 1);

    // Verify users are remapped
    final user1Result = await db.query('users', where: 'uid = ?', whereArgs: ['user-super-admin']);
    expect(user1Result.first['role_id'], 'role-owner');
    expect(user1Result.first['is_dirty'], 1);

    final user2Result = await db.query('users', where: 'uid = ?', whereArgs: ['user-dynamic-owner']);
    expect(user2Result.first['role_id'], 'role-owner');
    expect(user2Result.first['is_dirty'], 1);

    // Verify legacy roles are deleted
    final legacyRolesResult = await db.query('roles', where: 'id = ? OR id = ?', whereArgs: ['role-super-admin', 'dynamic-owner-id-123']);
    expect(legacyRolesResult.isEmpty, true);
  });

  test('v12 migration handles already migrated state safely', () async {
    // Insert canonical role-owner
    await db.insert('roles', {
      'id': 'role-owner',
      'name': 'Owner',
      'priority': 0, // Should be upgraded to 1000
      'is_system_role': 1,
      'is_editable': 1, // Should be downgraded to 0
      'is_deletable': 0,
      'permissions': '[]',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_dirty': 0,
    });

    // Run Migration
    await runMigration();

    // Verify role-owner properties are enforced
    final roleOwnerResult = await db.query('roles', where: 'id = ?', whereArgs: ['role-owner']);
    expect(roleOwnerResult.length, 1);
    expect(roleOwnerResult.first['priority'], 1000);
    expect(roleOwnerResult.first['is_editable'], 0);
  });
}

