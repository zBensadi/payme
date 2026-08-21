import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/database/database_service.dart';
import 'package:payme/core/database/migration_runner.dart';
import 'package:payme/core/logging/logger_service.dart';
import 'package:logger/logger.dart';
import 'package:payme/data/datasources/local/client_local_datasource.dart';
import 'package:payme/data/datasources/local/client_visibility_local_datasource.dart';
import 'package:payme/data/models/client_model.dart';
import 'package:payme/data/models/client_visibility_model.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = 'scratch/trace_db.sqlite';
  if (File(dbPath).existsSync()) {
    File(dbPath).deleteSync();
  }

  final db = await databaseFactory.openDatabase(dbPath, options: OpenDatabaseOptions(
    version: null,
    onOpen: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
  ));

  final runner = MigrationRunner(LoggerService(Logger()));
  await runner.runMigrations(db);

  final dbService = DatabaseService(db);
  final clientDataSource = ClientLocalDataSource(db);
  final visibilityDataSource = ClientVisibilityLocalDataSource(dbService);

  // Setup fake data
  await db.insert('roles', {
    'id': 'role_owner',
    'name': 'Owner',
    'priority': 1000,
    'permissions': '[]',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  });

  await db.insert('users', {
    'id': 'user_owner',
    'email': 'owner@test.com',
    'business_id': 'biz_1',
    'role_id': 'role_owner',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  });

  print('--- A. Before client save ---');
  final clientId = 'client_1';
  final businessId = 'biz_1';
  final userId = 'user_owner';

  final newClient = ClientModel(
    id: clientId,
    name: 'Test Client',
    
    visibilityType: 'specific_users',
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );

  print('--- B. After ClientRepository.create ---');
  await clientDataSource.create(newClient);
  final clientsAfterCreate = await db.rawQuery('SELECT id, visibility_type FROM clients WHERE id = ?', [clientId]);
  print('Clients row: $clientsAfterCreate');

  print('--- C/D. After ClientVisibilityRepository.addVisibility ---');
  await visibilityDataSource.addVisibility(ClientVisibilityModel(clientId: clientId, userId: userId));
  final visAfterAdd = await db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [clientId]);
  print('Visibility rows: $visAfterAdd');

  print('--- E/F/G/H. Simulating Client Sync ---');
  // Overwrite client as SyncService would
  final pulledClient = ClientModel(
    id: clientId,
    name: 'Test Client',
    
    visibilityType: 'specific_users',
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
  await clientDataSource.overwriteClient(pulledClient);

  print('--- I. After ClientLocalDataSource.overwriteClient ---');
  final visAfterOverwrite = await db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [clientId]);
  print('Visibility rows after client overwrite: $visAfterOverwrite');

  print('--- K. Simulating Visibility Sync ---');
  // SyncService fetches remote visibilities, let's say it's EMPTY because it wasn't pushed yet.
  final allRemoteVisibilities = <ClientVisibilityModel>[];
  final allRemoteSet = allRemoteVisibilities.map((e) => '${e.clientId}_${e.userId}').toSet();

  final localVisibilities = await visibilityDataSource.getAllVisibility();
  final localSet = localVisibilities.map((e) => '${e.clientId}_${e.userId}').toSet();

  for (final local in localVisibilities) {
    if (local.syncedAt != null) { // This is the logic in pullChanges!
      final key = '${local.clientId}_${local.userId}';
      if (!allRemoteSet.contains(key)) {
        await visibilityDataSource.removeVisibility(local.clientId, local.userId);
      }
    }
  }

  print('--- L. Final Visibility Query ---');
  final finalVis = await db.rawQuery('SELECT * FROM client_user_visibility WHERE client_id = ?', [clientId]);
  print('Final Visibility rows: $finalVis');

  final visibleClients = await clientDataSource.getAllVisible(visibleToUserId: userId);
  print('Visible Clients using query: ${visibleClients.map((e) => e.id).toList()}');

  await db.close();
  exit(0);
}
