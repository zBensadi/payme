import 'package:flutter_test/flutter_test.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_trigger.dart';
import 'package:payme/data/datasources/local/client_visibility_local_datasource.dart';
import 'package:payme/data/datasources/remote/client_visibility_remote_datasource.dart';
import 'package:payme/data/repositories_impl/client_visibility_repository_impl.dart';
import 'package:payme/domain/entities/client_visibility.dart';
import 'package:payme/data/models/client_visibility_model.dart';

class MockClientVisibilityLocalDataSource implements ClientVisibilityLocalDataSource {
  List<ClientVisibilityModel> mockAllVisibility = [];
  List<String> removedVisibilities = [];

  @override
  Future<void> addVisibility(ClientVisibilityModel visibility) async {}

  @override
  Future<void> clearDeletions(String clientId, String userId) async {}

  @override
  Future<List<ClientVisibilityModel>> getAllVisibility() async => mockAllVisibility;

  @override
  Future<List<Map<String, dynamic>>> getPendingDeletions() async => [];

  @override
  Future<List<ClientVisibilityModel>> getUnsyncedVisibility() async => [];

  @override
  Future<List<ClientVisibilityModel>> getVisibilityForClient(String clientId) async => [];

  @override
  Future<void> overwriteVisibility(ClientVisibilityModel visibility) async {}

  @override
  Future<void> removeVisibility(String clientId, String userId) async {
    removedVisibilities.add('${clientId}_$userId');
  }

  @override
  Future<void> updateSyncMetadata(String clientId, String userId, DateTime syncedAt) async {}
}

class MockClientVisibilityRemoteDataSource implements ClientVisibilityRemoteDataSource {
  List<ClientVisibilityModel> mockRemoteVisibility = [];
  List<ClientVisibilityModel> mockAllRemoteVisibility = [];

  @override
  Future<List<ClientVisibilityModel>> getModifiedSince(String businessId, DateTime? since) async {
    if (since == null) {
      return mockAllRemoteVisibility;
    }
    return mockRemoteVisibility;
  }

  @override
  Future<void> pushDeletions(String businessId, List<String> deletedDocIds) async {}

  @override
  Future<void> pushVisibilities(String businessId, List<ClientVisibilityModel> visibilities) async {}
}

class MockSyncTrigger implements SyncTrigger {
  List<SyncDomain?> requestedDomains = [];

  @override
  void requestSync([SyncDomain? domain]) {
    requestedDomains.add(domain);
  }

  @override
  void requestFullSync() {}

  @override
  Stream<SyncDomain> get syncRequested => const Stream.empty();
  @override
  void dispose() {}
}

void main() {
  group('ClientVisibilityRepositoryImpl Sync Trigger Tests', () {
    late ClientVisibilityRepositoryImpl repository;
    late MockClientVisibilityLocalDataSource localDataSource;
    late MockClientVisibilityRemoteDataSource remoteDataSource;
    late MockSyncTrigger syncTrigger;

    setUp(() {
      localDataSource = MockClientVisibilityLocalDataSource();
      remoteDataSource = MockClientVisibilityRemoteDataSource();
      syncTrigger = MockSyncTrigger();
      repository = ClientVisibilityRepositoryImpl(localDataSource, remoteDataSource, syncTrigger);
    });

    test('addVisibility requests sync for clientVisibility domain', () async {
      await repository.addVisibility(const ClientVisibility(clientId: 'c1', userId: 'u1'));
      expect(syncTrigger.requestedDomains.contains(SyncDomain.clientVisibility), true);
    });

    test('removeVisibility requests sync for clientVisibility domain', () async {
      await repository.removeVisibility('c1', 'u1');
      expect(syncTrigger.requestedDomains.contains(SyncDomain.clientVisibility), true);
    });

    test('pullChanges does NOT remove local mapping if remote fetch returns the same visibility mapping', () async {
      final now = DateTime.now();
      localDataSource.mockAllVisibility = [
        ClientVisibilityModel(clientId: 'c1', userId: 'u1', syncedAt: now),
      ];
      remoteDataSource.mockRemoteVisibility = [
        ClientVisibilityModel(clientId: 'c1', userId: 'u1', syncedAt: now),
      ];
      remoteDataSource.mockAllRemoteVisibility = [
        ClientVisibilityModel(clientId: 'c1', userId: 'u1', syncedAt: now),
      ];
      
      await repository.pullChanges('bus_1', now);
      
      expect(localDataSource.removedVisibilities.isEmpty, true);
    });

    test('pullChanges removes local mapping and creates tombstone if remote mapping is genuinely absent', () async {
      final now = DateTime.now();
      localDataSource.mockAllVisibility = [
        ClientVisibilityModel(clientId: 'c1', userId: 'u1', syncedAt: now),
      ];
      // Simulate remote having a DIFFERENT visibility, so getModifiedSince returns non-empty
      remoteDataSource.mockRemoteVisibility = [
        ClientVisibilityModel(clientId: 'c2', userId: 'u2', syncedAt: now),
      ];
      remoteDataSource.mockAllRemoteVisibility = [
        ClientVisibilityModel(clientId: 'c2', userId: 'u2', syncedAt: now),
      ];
      
      await repository.pullChanges('bus_1', now);
      
      expect(localDataSource.removedVisibilities.contains('c1_u1'), true);
    });
  });
}
