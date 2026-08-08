import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../../core/sync/synchronizable_repository.dart';
import '../../core/sync/sync_priority.dart';
import '../../core/sync/sync_result.dart';
import '../../core/sync/conflict_resolver.dart';
import '../../core/sync/sync_domain.dart';
import '../../core/sync/sync_trigger.dart';
import '../datasources/local/client_local_datasource.dart';
import '../datasources/remote/client_remote_datasource.dart';
import '../models/client_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/events/repository_event.dart';
import '../../../core/events/repository_change_publisher.dart';

class ClientRepositoryImpl implements ClientRepository, SynchronizableRepository, RepositoryChangePublisher {
  final ClientLocalDataSource _localDataSource;
  final ClientRemoteDataSource _remoteDataSource;
  final ConflictResolver<Client> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  ClientRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._conflictResolver,
    this._syncTrigger,
  );

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  @override
  void dispose() {
    _eventController.close();
  }

  @override
  SyncDomain get syncDomain => SyncDomain.clients;

  @override
  SyncPriority get syncPriority => SyncPriority.medium;

  @override
  Future<Result<List<Client>>> getAllVisible({String? searchQuery}) async {
    try {
      final models = await _localDataSource.getAllVisible(searchQuery: searchQuery);
      return Success(models);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load clients: $e'));
    }
  }

  @override
  Future<Result<List<Client>>> getAllDeleted({String? searchQuery}) async {
    try {
      final models = await _localDataSource.getAllDeleted(searchQuery: searchQuery);
      return Success(models);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load deleted clients: $e'));
    }
  }

  @override
  Future<Result<Client>> getById(String id) async {
    try {
      final model = await _localDataSource.getById(id);
      if (model == null) {
        return const Failure(ValidationFailure('Client not found.'));
      }
      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load client: $e'));
    }
  }

  @override
  Future<Result<bool>> checkDuplicate(String name, String? phone, {String? excludeId}) async {
    try {
      final matches = await _localDataSource.getByNameAndPhone(name, phone);
      if (excludeId != null) {
        return Success(matches.any((m) => m.id != excludeId));
      }
      return Success(matches.isNotEmpty);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to check for duplicate clients: $e'));
    }
  }

  @override
  Future<Result<Client>> create(Client client) async {
    try {
      final updatedClient = client.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = ClientModel.fromEntity(updatedClient);
      await _localDataSource.create(model);
      _syncTrigger.requestSync(syncDomain);
      return Success(updatedClient);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create client: $e'));
    }
  }

  @override
  Future<Result<Client>> update(Client client) async {
    try {
      final updatedClient = client.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = ClientModel.fromEntity(updatedClient);
      await _localDataSource.update(model);
      _syncTrigger.requestSync(syncDomain);
      return Success(updatedClient);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update client: $e'));
    }
  }

  @override
  Future<Result<void>> softDelete(String id, {Object? txn}) async {
    try {
      await _localDataSource.softDelete(id, txn: txn as dynamic);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete client: $e'));
    }
  }

  @override
  Future<Result<void>> restore(String id) async {
    try {
      await _localDataSource.restore(id);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to restore client: $e'));
    }
  }

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtyModels = await _localDataSource.getDirtyClients();
      if (dirtyModels.isEmpty) return const SyncResult(skipped: 0);

      final dirtyClients = dirtyModels.map((m) => m as Client).toList();
      
      await _remoteDataSource.pushClients(businessId, dirtyClients);
      
      final ids = dirtyClients.map((c) => c.id).toList();
      await _localDataSource.updateSyncMetadata(ids, DateTime.now().toUtc());
      
      return SyncResult(uploaded: dirtyClients.length);
    } catch (e, stack) {
      debugPrint('Client push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteClients = await _remoteDataSource.pullClients(businessId, lastSyncTime);
      if (remoteClients.isEmpty) return const SyncResult(skipped: 0);

      int downloaded = 0;
      int conflicts = 0;

      for (final remoteClient in remoteClients) {
        final localModel = await _localDataSource.getById(remoteClient.id);
        
        if (localModel == null) {
          // Local record missing → insert into SQLite
          await _localDataSource.overwriteClient(ClientModel.fromEntity(remoteClient));
          downloaded++;
        } else {
          final localClient = localModel as Client;
          
          if (remoteClient.updatedAt.compareTo(localClient.updatedAt) <= 0) {
            // remote.updatedAt <= local.updatedAt → ignore remote record
            continue;
          }

          if (!localClient.isDirty) {
            // Local record exists and is clean → overwrite
            await _localDataSource.overwriteClient(ClientModel.fromEntity(remoteClient));
            downloaded++;
          } else {
            // Local record exists and is dirty → conflict
            conflicts++;
            final winningClient = _conflictResolver.resolve(
              localClient,
              remoteClient,
            );
            
            if (winningClient == remoteClient) {
              await _localDataSource.overwriteClient(ClientModel.fromEntity(winningClient));
              downloaded++;
            }
          }
        }
      }

      if (conflicts > 0 || downloaded > 0) {
        _eventController.add(RepositoryEvent(
          type: conflicts > 0 ? RepositoryEventType.conflictResolved : RepositoryEventType.remoteSynchronization,
          domain: syncDomain,
          timestamp: DateTime.now().toUtc(),
          affectedRows: downloaded + conflicts,
        ));
      }

      return SyncResult(downloaded: downloaded, conflicts: conflicts);
    } catch (e, stack) {
      debugPrint('Client pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
