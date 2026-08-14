import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/sync/sync_domain.dart';
import '../../core/sync/sync_priority.dart';
import '../../core/sync/sync_result.dart';
import '../../core/sync/sync_trigger.dart';
import '../../domain/entities/client_visibility.dart';
import '../../domain/repositories/client_visibility_repository.dart';
import '../datasources/local/client_visibility_local_datasource.dart';
import '../datasources/remote/client_visibility_remote_datasource.dart';
import '../models/client_visibility_model.dart';
import '../../../core/events/repository_event.dart';

class ClientVisibilityRepositoryImpl implements ClientVisibilityRepository {
  final ClientVisibilityLocalDataSource _localDataSource;
  final ClientVisibilityRemoteDataSource _remoteDataSource;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  ClientVisibilityRepositoryImpl(this._localDataSource, this._remoteDataSource, this._syncTrigger);

  @override
  SyncDomain get syncDomain => SyncDomain.clientVisibility;

  @override
  SyncPriority get syncPriority => SyncPriority.level4ClientVisibility;

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  void dispose() {
    _eventController.close();
  }

  @override
  Future<Result<void>> addVisibility(ClientVisibility visibility) async {
    try {
      await _localDataSource.addVisibility(ClientVisibilityModel.fromEntity(visibility));
      print('[TRACE-VISIBILITY] ClientVisibilityRepositoryImpl.addVisibility: ${visibility.clientId} -> ${visibility.userId}');
      _syncTrigger.requestSync(syncDomain);
      _eventController.add(RepositoryEvent(
        type: RepositoryEventType.localMutation,
        domain: syncDomain,
        timestamp: DateTime.now().toUtc(),
      ));
      return const Success(null);
    } catch (e, stack) {

      debugPrint('Failed to add client visibility: $e\n$stack');

      return Failure(DatabaseFailure(e.toString()));

    }

  }



  @override
  Future<Result<void>> removeVisibility(String clientId, String userId) async {
    try {
      await _localDataSource.removeVisibility(clientId, userId);
      _syncTrigger.requestSync(syncDomain);
      _eventController.add(RepositoryEvent(
        type: RepositoryEventType.localMutation,
        domain: syncDomain,
        timestamp: DateTime.now().toUtc(),
      ));
      return const Success(null);
    } catch (e, stack) {
      debugPrint('Failed to remove client visibility: $e\n$stack');
      return Failure(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ClientVisibility>>> getVisibilityForClient(String clientId) async {
    try {
      final models = await _localDataSource.getVisibilityForClient(clientId);
      return Success(models);
    } catch (e, stack) {
      debugPrint('Failed to get client visibility: $e\n$stack');
      return Failure(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteVisibilities = await _remoteDataSource.getModifiedSince(businessId, lastSyncTime);
      if (remoteVisibilities.isEmpty) {
        return const SyncResult(downloaded: 0);
      }

      int downloaded = 0;
      final localVisibilities = await _localDataSource.getAllVisibility();
      final localSet = localVisibilities.map((e) => '${e.clientId}_${e.userId}').toSet();
      final remoteSet = remoteVisibilities.map((e) => '${e.clientId}_${e.userId}').toSet();

      final allRemoteVisibilities = await _remoteDataSource.getModifiedSince(businessId, null); // Always full pull
      final allRemoteSet = allRemoteVisibilities.map((e) => '${e.clientId}_${e.userId}').toSet();

      // Add missing local
      for (final remote in allRemoteVisibilities) {
        final key = '${remote.clientId}_${remote.userId}';
        if (!localSet.contains(key)) {
          await _localDataSource.overwriteVisibility(remote);
          downloaded++;
        }
      }

      // Remove local if not in remote, but only if they have been synced before.
      for (final local in localVisibilities) {
        if (local.syncedAt != null) {
          final key = '${local.clientId}_${local.userId}';
          if (!allRemoteSet.contains(key)) {
            await _localDataSource.removeVisibility(local.clientId, local.userId);
            downloaded++;
          }
        }
      }

      if (downloaded > 0) {
        _eventController.add(RepositoryEvent(
          type: RepositoryEventType.remoteSynchronization,
          domain: syncDomain,
          timestamp: DateTime.now().toUtc(),
          affectedRows: downloaded,
        ));
      }

      return SyncResult(downloaded: downloaded);
    } catch (e, stack) {
      debugPrint('Client visibility pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }



  @override

  Future<SyncResult> pushChanges(String businessId) async {

    try {

      final unsynced = await _localDataSource.getUnsyncedVisibility();

      final pendingDeletions = await _localDataSource.getPendingDeletions();

      

      if (unsynced.isEmpty && pendingDeletions.isEmpty) {

        return const SyncResult(uploaded: 0);

      }

      

      final now = DateTime.now();

      

      // Push additions

      if (unsynced.isNotEmpty) {

        await _remoteDataSource.pushVisibilities(businessId, unsynced);

        for (final v in unsynced) {

          await _localDataSource.updateSyncMetadata(v.clientId, v.userId, now);

        }

      }

      

      // Push deletions

      if (pendingDeletions.isNotEmpty) {

        final deletedDocIds = pendingDeletions.map((row) => "${row['client_id']}_${row['user_id']}").toList();

        await _remoteDataSource.pushDeletions(businessId, deletedDocIds);

        for (final row in pendingDeletions) {

          await _localDataSource.clearDeletions(row['client_id'] as String, row['user_id'] as String);

        }

      }

      

      return SyncResult(uploaded: unsynced.length + pendingDeletions.length);

    } catch (e, stack) {

      debugPrint('Client visibility push failed: $e\n$stack');

      return const SyncResult(failed: 1);

    }

  }

}

