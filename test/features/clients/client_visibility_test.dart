import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/logging/logger_service.dart';
import 'package:payme/data/datasources/local/client_visibility_local_datasource.dart';
import 'package:payme/data/models/client_visibility_model.dart';
import 'package:logger/logger.dart';

import 'package:payme/data/datasources/local/client_local_datasource.dart';
import 'package:payme/data/models/client_model.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;


  late Database db;
  late ClientVisibilityLocalDataSource dataSource;
  late ClientLocalDataSource clientDataSource;


  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
      version: null,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ));

    final runner = MigrationRunner(LoggerService(Logger()));
    await runner.runMigrations(db);


    final dbService = DatabaseService(db);
    dataSource = ClientVisibilityLocalDataSource(dbService);
    clientDataSource = ClientLocalDataSource(db);



    // Insert mock role to satisfy foreign keys
    await db.insert('roles', {
      'id': 'role_1',
      'name': 'Role 1',
      'priority': 10,
      'permissions': '[]',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      
    });
    
    // Insert mock client and user to satisfy foreign keys

    await db.insert('clients', {
      'id': 'client_A',
      'name': 'Client A',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'visibility_type': 'specific_users',
    });
    
    await db.insert('users', {
      'id': 'user_B',
      'email': 'userB@example.com',
      'business_id': 'biz_1',
      'role_id': 'role_1',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('Client Visibility Tombstone Tests', () {
    test('Offline removal creates tombstone', () async {
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      
      var visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1);

      await dataSource.removeVisibility('client_A', 'user_B');

      visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 0);

      final deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 1);
      expect(deletions.first['client_id'], 'client_A');
      expect(deletions.first['user_id'], 'user_B');
    });

    test('Duplicate removal is idempotent', () async {
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      await dataSource.removeVisibility('client_A', 'user_B');
      await dataSource.removeVisibility('client_A', 'user_B'); // Duplicate

      final deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 1); // Should not throw and should not duplicate
    });

    test('Remove -> re-add clears/reconciles tombstone', () async {
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      
      // Remove -> creates tombstone
      await dataSource.removeVisibility('client_A', 'user_B');
      var deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 1);

      // Re-add -> should reconcile and remove tombstone
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      
      deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 0);
      
      final visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1);
    });

    test('Successful push clears tombstone (clearDeletions)', () async {
      await dataSource.removeVisibility('client_A', 'user_B');
      
      var deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 1);
      
      await dataSource.clearDeletions('client_A', 'user_B');
      
      deletions = await dataSource.getPendingDeletions();
      expect(deletions.length, 0);
    });
  });


  group('Client Visibility Sync Blocker Regression Tests', () {
    test('overwriteClient does not cascade delete visibility mapping', () async {
      // 1. Add mapping
      await dataSource.addVisibility(const ClientVisibilityModel(clientId: 'client_A', userId: 'user_B'));
      var visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1);

      // 2. Overwrite client (simulating a sync pull)
      final clientToOverwrite = ClientModel(
        id: 'client_A',
        name: 'Client A Updated',
        visibilityType: 'specific_users',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await clientDataSource.overwriteClient(clientToOverwrite);

      // 3. Verify visibility mapping still exists
      visibilities = await dataSource.getVisibilityForClient('client_A');
      expect(visibilities.length, 1, reason: 'overwriteClient should not delete child visibility rows');
      expect(visibilities.first.userId, 'user_B');
    });
  });}
