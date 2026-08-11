import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/conflict_resolver.dart';
import '../../../core/sync/sync_priority.dart';
import '../../../core/sync/sync_result.dart';
import '../../../core/sync/synchronizable_repository.dart';
import '../../../core/sync/sync_domain.dart';
import '../../../core/sync/sync_trigger.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/business_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../datasources/file/logo_file_datasource.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../datasources/remote/settings_remote_datasource.dart';

import '../../../core/events/repository_event.dart';
import '../../../core/events/repository_change_publisher.dart';

class SettingsRepositoryImpl implements SettingsRepository, SynchronizableRepository, RepositoryChangePublisher {
  final SettingsLocalDataSource _localDataSource;
  final SettingsRemoteDataSource _remoteDataSource;
  final LogoFileDataSource _fileDataSource;
  final ConflictResolver<BusinessSettings> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  SettingsRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._fileDataSource,
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
  SyncDomain get syncDomain => SyncDomain.settings;

  @override
  SyncPriority get syncPriority => SyncPriority.high;

  @override
  Future<Result<BusinessSettings>> getSettings() async {
    try {
      final settings = await _localDataSource.getSettings();
      return Success(settings);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Result<BusinessSettings>> updateSettings(
    BusinessSettings settings, {
    String? newLogoSourcePath,
  }) async {
    try {
      BusinessSettings updatedSettings = settings;

      if (newLogoSourcePath != null) {
        if (settings.logoPath != null) {
          await _fileDataSource.deleteLogo(settings.logoPath!);
        }

        final extension = p.extension(newLogoSourcePath).toLowerCase().replaceAll('.', '');
        final type = ['jpg', 'jpeg', 'png'].contains(extension) ? (extension == 'jpeg' ? 'jpg' : extension) : 'png';
        final newFileName = 'logo_${IdGenerator.generateUniqueId()}.$type';
        
        final relativePath = await _fileDataSource.saveLogo(newLogoSourcePath, newFileName);
        updatedSettings = updatedSettings.copyWith(logoPath: relativePath);
      }

      await _localDataSource.updateSettings(updatedSettings);
      _syncTrigger.requestSync(syncDomain);
      return Success(updatedSettings);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to update settings: $e'));
    }
  }

  @override
  Future<Result<void>> lockCurrency() async {
    try {
      await _localDataSource.lockCurrency();
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to lock currency: $e'));
    }
  }

  // --- SynchronizableRepository Implementation ---

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtySettings = await _localDataSource.getDirtySettings();
      if (dirtySettings == null) {
        return const SyncResult(skipped: 1);
      }

      await _remoteDataSource.pushSettings(businessId, dirtySettings);
      
      await _localDataSource.updateSyncMetadata(
        id: 1,
        remoteId: businessId,
        syncedAt: DateTime.now(),
        isDirty: false,
      );

      return const SyncResult(uploaded: 1);
    } catch (e, stack) {
      debugPrint('Settings push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteSettings = await _remoteDataSource.pullSettings(businessId);
      if (remoteSettings == null) {
        return const SyncResult(skipped: 1);
      }

      final localSettings = await _localDataSource.getSettingsOrNull();

      if (localSettings != null && localSettings.isDirty) {
        // Conflict!
        final resolvedSettings = _conflictResolver.resolve(localSettings, remoteSettings);
        
        if (resolvedSettings.isDirty) {
           await _localDataSource.updateSettings(resolvedSettings); // Keep dirty
           return const SyncResult(conflicts: 1, skipped: 1);
        } else {
           await _localDataSource.overwriteSettings(resolvedSettings);
           _eventController.add(RepositoryEvent(
             type: RepositoryEventType.conflictResolved,
             domain: syncDomain,
             timestamp: DateTime.now().toUtc(),
             affectedRows: 1,
           ));
           return const SyncResult(conflicts: 1, downloaded: 1);
        }
      } else {
        await _localDataSource.overwriteSettings(remoteSettings);
        _eventController.add(RepositoryEvent(
          type: RepositoryEventType.remoteSynchronization,
          domain: syncDomain,
          timestamp: DateTime.now().toUtc(),
          affectedRows: 1,
        ));
        return const SyncResult(downloaded: 1);
      }
    } catch (e, stack) {
      debugPrint('Settings pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
