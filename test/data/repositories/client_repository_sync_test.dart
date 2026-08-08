import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/core/sync/conflict_resolver.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/domain/entities/client.dart';
import 'package:payme/data/repositories_impl/client_repository_impl.dart';
import 'package:payme/data/datasources/local/client_local_datasource.dart';
import 'package:payme/data/datasources/remote/client_remote_datasource.dart';
import 'package:payme/data/models/client_model.dart';
import 'package:sqflite/sqflite.dart';

class MockClientLocalDataSource implements ClientLocalDataSource {
  List<ClientModel> _dirtyClients = [];
  Map<String, ClientModel> _db = {};
  bool wasUpdateSyncMetadataCalled = false;
  List<String> lastUpdatedIds = [];

  void setMockDirtyClients(List<ClientModel> clients) {
    _dirtyClients = clients;
  }

  void setMockDb(List<ClientModel> clients) {
    _db = {for (var c in clients) c.id: c};
  }

  @override
  Future<List<ClientModel>> getDirtyClients() async => _dirtyClients;

  @override
  Future<ClientModel?> getById(String id) async => _db[id];

  @override
  Future<void> overwriteClient(ClientModel client) async {
    _db[client.id] = client;
  }

  @override
  Future<void> updateSyncMetadata(List<String> ids, DateTime syncedAt) async {
    wasUpdateSyncMetadataCalled = true;
    lastUpdatedIds = ids;
  }

  @override
  Future<void> create(ClientModel client) async {
    _db[client.id] = client;
  }

  @override
  Future<void> update(ClientModel client) async {
    _db[client.id] = client;
  }

  @override
  Future<void> softDelete(String id, {Transaction? txn}) async {
    if (_db.containsKey(id)) {
      final old = _db[id]!;
      _db[id] = ClientModel.fromEntity(old.copyWith(isDeleted: true, isDirty: true));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockClientRemoteDataSource implements ClientRemoteDataSource {
  List<Client> pushedClients = [];
  List<Client> pulledClients = [];
  DateTime? lastSyncTimeUsed;

  @override
  Future<void> pushClients(String businessId, List<Client> clients) async {
    pushedClients.addAll(clients);
  }

  @override
  Future<List<Client>> pullClients(String businessId, DateTime? lastSyncTime) async {
    lastSyncTimeUsed = lastSyncTime;
    return pulledClients;
  }
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
  late ClientRepositoryImpl repository;
  late MockClientLocalDataSource localDataSource;
  late MockClientRemoteDataSource remoteDataSource;
  late ConflictResolver<Client> conflictResolver;
  late DummySyncTrigger syncTrigger;

  final now = DateTime.now().toUtc();
  final old = now.subtract(const Duration(days: 1));
  final newer = now.add(const Duration(days: 1));

  setUp(() {
    localDataSource = MockClientLocalDataSource();
    remoteDataSource = MockClientRemoteDataSource();
    conflictResolver = DefaultConflictResolver<Client>();
    syncTrigger = DummySyncTrigger();

    repository = ClientRepositoryImpl(
      localDataSource,
      remoteDataSource,
      conflictResolver,
      syncTrigger,
    );
  });

  group('ClientRepositoryImpl Sync - Push', () {
    test('pushChanges pushes multiple dirty records in one batch and updates metadata', () async {
      final client1 = Client(id: '1', name: 'A', createdAt: now, updatedAt: now, isDirty: true);
      final client2 = Client(id: '2', name: 'B', createdAt: now, updatedAt: now, isDirty: true);
      
      localDataSource.setMockDirtyClients([
        ClientModel.fromEntity(client1),
        ClientModel.fromEntity(client2),
      ]);

      final result = await repository.pushChanges('biz1');

      expect(result.uploaded, 2);
      expect(remoteDataSource.pushedClients.length, 2);
      expect(localDataSource.wasUpdateSyncMetadataCalled, true);
      expect(localDataSource.lastUpdatedIds, ['1', '2']);
    });

    test('pushChanges skips if no dirty clients', () async {
      localDataSource.setMockDirtyClients([]);

      final result = await repository.pushChanges('biz1');

      expect(result.skipped, 0);
      expect(result.uploaded, 0);
      expect(remoteDataSource.pushedClients.isEmpty, true);
    });
  });

  group('ClientRepositoryImpl Sync - Pull', () {
    test('pullChanges inserts missing local record', () async {
      final remoteClient = Client(id: '1', name: 'Remote', createdAt: now, updatedAt: now, isDirty: false);
      remoteDataSource.pulledClients = [remoteClient];
      
      final result = await repository.pullChanges('biz1', null);

      expect(result.downloaded, 1);
      final local = await localDataSource.getById('1');
      expect(local?.name, 'Remote');
    });

    test('pullChanges ignores remote record if remote.updatedAt <= local.updatedAt', () async {
      final localClient = Client(id: '1', name: 'Local', createdAt: old, updatedAt: now, isDirty: false);
      localDataSource.setMockDb([ClientModel.fromEntity(localClient)]);
      
      final remoteClient = Client(id: '1', name: 'Remote', createdAt: old, updatedAt: old, isDirty: false);
      remoteDataSource.pulledClients = [remoteClient];
      
      final result = await repository.pullChanges('biz1', null);

      expect(result.downloaded, 0);
      final local = await localDataSource.getById('1');
      expect(local?.name, 'Local');
    });

    test('pullChanges overwrites clean local record if remote.updatedAt > local.updatedAt', () async {
      final localClient = Client(id: '1', name: 'Local', createdAt: old, updatedAt: old, isDirty: false);
      localDataSource.setMockDb([ClientModel.fromEntity(localClient)]);
      
      final remoteClient = Client(id: '1', name: 'Remote', createdAt: old, updatedAt: newer, isDirty: false);
      remoteDataSource.pulledClients = [remoteClient];
      
      final result = await repository.pullChanges('biz1', null);

      expect(result.downloaded, 1);
      final local = await localDataSource.getById('1');
      expect(local?.name, 'Remote');
    });

    test('pullChanges delegates to conflict resolver if local is dirty', () async {
      final localClient = Client(id: '1', name: 'Local', createdAt: old, updatedAt: now, isDirty: true);
      localDataSource.setMockDb([ClientModel.fromEntity(localClient)]);
      
      // Assume remote is newer to trigger conflict
      final remoteClient = Client(id: '1', name: 'Remote', createdAt: old, updatedAt: newer, isDirty: false);
      remoteDataSource.pulledClients = [remoteClient];
      
      // Default conflict resolver favors local
      final result = await repository.pullChanges('biz1', null);

      expect(result.conflicts, 1);
      // Because local wins, downloaded shouldn't increase, and local stays 'Local'
      expect(result.downloaded, 0);
      final local = await localDataSource.getById('1');
      expect(local?.name, 'Local');
    });
  });

  group('ClientRepositoryImpl - Offline First Behaviors', () {
    test('create client marks as dirty and updates timestamp', () async {
      final client = Client(id: '1', name: 'A', createdAt: old, updatedAt: old, isDirty: false);
      
      final result = await repository.create(client);
      
      expect(result is Success<Client>, true);
      final saved = await localDataSource.getById('1');
      expect(saved?.isDirty, true);
      expect(saved?.updatedAt.isAfter(old), true);
    });

    test('update client marks as dirty and updates timestamp', () async {
      final client = Client(id: '1', name: 'A', createdAt: old, updatedAt: old, isDirty: false);
      
      final result = await repository.update(client);
      
      expect(result is Success<Client>, true);
      final saved = await localDataSource.getById('1');
      expect(saved?.isDirty, true);
      expect(saved?.updatedAt.isAfter(old), true);
    });
  });
}
