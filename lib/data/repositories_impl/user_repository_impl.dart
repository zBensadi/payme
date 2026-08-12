import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';
import '../models/app_user_model.dart';
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

class UserRepositoryImpl implements UserRepository, SynchronizableRepository, RepositoryChangePublisher {
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource _remoteDataSource;
  final ConflictResolver<AppUser> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  UserRepositoryImpl(
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
  SyncDomain get syncDomain => SyncDomain.users;

  @override
  SyncPriority get syncPriority => SyncPriority.level3Users;

  @override
  Future<Result<List<AppUser>>> getAllUsers() async {
    try {
      final users = await _localDataSource.getAll();
      return Success(users);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load users: $e'));
    }
  }

  @override
  Future<Result<AppUser?>> getUserById(String id) async {
    try {
      final user = await _localDataSource.getById(id);
      return Success(user);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load user: $e'));
    }
  }

  @override
  Future<Result<void>> createUser(AppUser user) async {
    try {
      final updatedUser = user.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = AppUserModel.fromEntity(updatedUser);
      await _localDataSource.create(model);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to create user: $e'));
    }
  }

  @override
  Future<Result<void>> updateUser(AppUser user) async {
    try {
      final updatedUser = user.copyWith(
        isDirty: true,
        updatedAt: DateTime.now().toUtc(),
      );
      final model = AppUserModel.fromEntity(updatedUser);
      await _localDataSource.update(model);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update user: $e'));
    }
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    try {
      await _localDataSource.delete(id);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to delete user: $e'));
    }
  }

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtyModels = await _localDataSource.getDirtyUsers();
      if (dirtyModels.isEmpty) return const SyncResult(skipped: 0);

      final dirtyUsers = dirtyModels.map((m) => m as AppUser).toList();
      
      await _remoteDataSource.pushUsers(businessId, dirtyUsers);
      
      final ids = dirtyUsers.map((c) => c.uid).toList();
      await _localDataSource.updateSyncMetadata(ids, DateTime.now().toUtc());
      
      return SyncResult(uploaded: dirtyUsers.length);
    } catch (e, stack) {
      debugPrint('User push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteUsers = await _remoteDataSource.pullUsers(businessId, lastSyncTime);
      if (remoteUsers.isEmpty) return const SyncResult(skipped: 0);

      int downloaded = 0;
      int conflicts = 0;

      for (final remoteUser in remoteUsers) {
        final localModel = await _localDataSource.getById(remoteUser.uid);
        
        if (localModel == null) {
          await _localDataSource.overwriteUser(AppUserModel.fromEntity(remoteUser));
          downloaded++;
        } else {
          final localUser = localModel as AppUser;
          
          if (remoteUser.updatedAt.compareTo(localUser.updatedAt) <= 0) {
            continue;
          }

          if (!localUser.isDirty) {
            await _localDataSource.overwriteUser(AppUserModel.fromEntity(remoteUser));
            downloaded++;
          } else {
            conflicts++;
            final winningUser = _conflictResolver.resolve(
              localUser,
              remoteUser,
            );
            
            if (winningUser == remoteUser) {
              await _localDataSource.overwriteUser(AppUserModel.fromEntity(winningUser));
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
      debugPrint('User pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
