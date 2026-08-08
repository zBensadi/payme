import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/sync/conflict_resolver.dart';
import 'package:payme/data/datasources/local/client_local_datasource.dart';
import 'package:payme/data/datasources/remote/client_remote_datasource.dart';
import 'package:payme/data/repositories_impl/client_repository_impl.dart';
import 'package:payme/domain/entities/client.dart';

import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_trigger.dart';

class DummyClientRemoteDataSource implements ClientRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummySyncTrigger implements SyncTrigger {
  @override
  void requestSync(SyncDomain domain) {}

  @override
  void requestFullSync() {}

  @override
  Stream<SyncDomain> get syncRequested => Stream.empty();

  @override
  void dispose() {}
}

void main() {
  late Database db;
  late ClientRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE clients (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    phone TEXT,
                    email TEXT,
                    address TEXT,
                    notes TEXT,
                    is_deleted INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    remote_id TEXT,
                    synced_at TEXT,
                    is_dirty INTEGER NOT NULL DEFAULT 0
                )
              ''');
            }));

    final dataSource = ClientLocalDataSource(db);
    final remoteDataSource = DummyClientRemoteDataSource();
    final conflictResolver = DefaultConflictResolver<Client>();
    final syncTrigger = DummySyncTrigger();
    repository = ClientRepositoryImpl(dataSource, remoteDataSource, conflictResolver, syncTrigger);
  });

  tearDown(() async {
    await db.close();
  });

  test('Create and retrieve client', () async {
    final client = Client(
      id: '1',
      name: 'Test Client',
      phone: '12345',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await repository.create(client);
    expect(result, isA<Success<Client>>());

    final visibleResult = await repository.getAllVisible();
    final visible = (visibleResult as Success<List<Client>>).value;
    expect(visible.length, 1);
    expect(visible.first.name, 'Test Client');
  });

  test('Soft delete moves client to deleted list', () async {
    final client = Client(
      id: '1',
      name: 'Test Client',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.create(client);
    await repository.softDelete('1');

    final visibleResult = await repository.getAllVisible();
    final visible = (visibleResult as Success<List<Client>>).value;
    expect(visible.isEmpty, isTrue);

    final deletedResult = await repository.getAllDeleted();
    final deleted = (deletedResult as Success<List<Client>>).value;
    expect(deleted.length, 1);
    expect(deleted.first.isDeleted, isTrue);
  });

  test('Restore moves client back to visible list', () async {
    final client = Client(
      id: '1',
      name: 'Test Client',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repository.create(client);
    await repository.softDelete('1');
    await repository.restore('1');

    final visibleResult = await repository.getAllVisible();
    final visible = (visibleResult as Success<List<Client>>).value;
    expect(visible.length, 1);
    expect(visible.first.isDeleted, isFalse);

    final deletedResult = await repository.getAllDeleted();
    final deleted = (deletedResult as Success<List<Client>>).value;
    expect(deleted.isEmpty, isTrue);
  });

  test('Search filtering', () async {
    await repository.create(Client(id: '1', name: 'Alpha', phone: '111', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    await repository.create(Client(id: '2', name: 'Bravo', phone: '222', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    
    final result = await repository.getAllVisible(searchQuery: 'Alpha');
    final clients = (result as Success<List<Client>>).value;
    expect(clients.length, 1);
    expect(clients.first.name, 'Alpha');

    final resultPhone = await repository.getAllVisible(searchQuery: '22');
    final clientsPhone = (resultPhone as Success<List<Client>>).value;
    expect(clientsPhone.length, 1);
    expect(clientsPhone.first.name, 'Bravo');
  });

  test('Duplicate check', () async {
    await repository.create(Client(id: '1', name: 'Duplicate', phone: '123', createdAt: DateTime.now(), updatedAt: DateTime.now()));
    
    final check1 = await repository.checkDuplicate('Duplicate', '123');
    expect((check1 as Success<bool>).value, isTrue);

    final check2 = await repository.checkDuplicate('Duplicate', '456');
    expect((check2 as Success<bool>).value, isFalse);

    final check3 = await repository.checkDuplicate('Other', '123');
    expect((check3 as Success<bool>).value, isFalse);
    
    // Check excluding self
    final check4 = await repository.checkDuplicate('Duplicate', '123', excludeId: '1');
    expect((check4 as Success<bool>).value, isFalse);
  });
}
