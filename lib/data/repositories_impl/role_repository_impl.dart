import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/local/role_local_datasource.dart';
import '../datasources/remote/role_remote_datasource.dart';
import '../models/user_role_model.dart';
import '../../core/sync/synchronizable_repository.dart';
import '../../core/sync/sync_priority.dart';
import '../../core/sync/sync_result.dart';
import '../../core/sync/conflict_resolver.dart';
import '../../core/sync/sync_domain.dart';
import '../../core/sync/sync_trigger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/events/repository_event.dart';
import '../../../core/events/repository_change_publisher.dart';

class RoleRepositoryImpl implements RoleRepository, SynchronizableRepository, RepositoryChangePublisher {
  final RoleLocalDataSource _localDataSource;
  final RoleRemoteDataSource _remoteDataSource;
  final ConflictResolver<UserRole> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  RoleRepositoryImpl(
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
  SyncDomain get syncDomain => SyncDomain.roles;

  @override
  SyncPriority get syncPriority => SyncPriority.level2Roles;

  @override
  Future<Result<List<UserRole>>> getAllRoles() async {
    try {
      final roles = await _localDataSource.getAll();
      return Success(roles);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load roles: $e'));
    }
  }

  @override
  Future<Result<UserRole?>> getRoleById(String id) async {
    try {
      final role = await _localDataSource.getById(id);
      return Success(role);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load role: $e'));
    }
  }

  @override
  Future<Result<void>> createRole(UserRole role) async {
    try {
      final updatedRole = role.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = UserRoleModel.fromEntity(updatedRole);
      await _localDataSource.create(model);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create role: $e'));
    }
  }

  @override
  Future<Result<void>> updateRole(UserRole role) async {
    try {
      final updatedRole = role.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = UserRoleModel.fromEntity(updatedRole);
      await _localDataSource.update(model);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update role: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRole(String id) async {
    try {
      await _localDataSource.delete(id);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete role: $e'));
    }
  }

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtyModels = await _localDataSource.getDirtyRoles();
      if (dirtyModels.isEmpty) return const SyncResult(skipped: 0);

      final dirtyRoles = dirtyModels.map((m) => m as UserRole).toList();
      
      await _remoteDataSource.pushRoles(businessId, dirtyRoles);
      
      final ids = dirtyRoles.map((c) => c.id).toList();
      await _localDataSource.updateSyncMetadata(ids, DateTime.now().toUtc());
      
      return SyncResult(uploaded: dirtyRoles.length);
    } catch (e, stack) {
      debugPrint('Role push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteRoles = await _remoteDataSource.pullRoles(businessId, lastSyncTime);
      if (remoteRoles.isEmpty) return const SyncResult(skipped: 0);

      int downloaded = 0;
      int conflicts = 0;

      for (final remoteRole in remoteRoles) {
        final localModel = await _localDataSource.getById(remoteRole.id);
        
        if (localModel == null) {
          await _localDataSource.overwriteRole(UserRoleModel.fromEntity(remoteRole));
          downloaded++;
        } else {
          final localRole = localModel as UserRole;
          
          if (remoteRole.updatedAt.compareTo(localRole.updatedAt) <= 0) {
            continue;
          }

          if (!localRole.isDirty) {
            await _localDataSource.overwriteRole(UserRoleModel.fromEntity(remoteRole));
            downloaded++;
          } else {
            conflicts++;
            final winningRole = _conflictResolver.resolve(
              localRole,
              remoteRole,
            );
            
            if (winningRole == remoteRole) {
              await _localDataSource.overwriteRole(UserRoleModel.fromEntity(winningRole));
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
      debugPrint('Role pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
