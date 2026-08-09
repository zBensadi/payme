import 'package:sqflite/sqflite.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/accounting_year.dart';
import '../../domain/repositories/accounting_year_repository.dart';
import '../datasources/local/accounting_year_local_datasource.dart';
import '../models/accounting_year_model.dart';
import '../../core/sync/synchronizable_repository.dart';
import '../../core/sync/sync_priority.dart';
import '../../core/sync/sync_result.dart';
import '../../core/sync/conflict_resolver.dart';
import '../../core/sync/sync_domain.dart';
import '../../core/sync/sync_trigger.dart';
import '../../../core/events/repository_event.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../datasources/remote/accounting_year_remote_datasource.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AccountingYearRepositoryImpl implements AccountingYearRepository, SynchronizableRepository, RepositoryChangePublisher {
  final AccountingYearLocalDataSource _localDataSource;
  final AccountingYearRemoteDataSource _remoteDataSource;
  final ConflictResolver<AccountingYear> _conflictResolver;
  final SyncTrigger _syncTrigger;

  final _eventController = StreamController<RepositoryEvent>.broadcast();

  AccountingYearRepositoryImpl(
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
  SyncDomain get syncDomain => SyncDomain.accountingYears;

  @override
  SyncPriority get syncPriority => SyncPriority.medium;


  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    try {
      final models = await _localDataSource.getAll();
      return Success(models.map((m) => m as AccountingYear).toList());
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load accounting years: $e'));
    }
  }

  @override
  Future<Result<AccountingYear?>> getActive() async {
    try {
      final model = await _localDataSource.getActive();
      return Success(model);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to load active accounting year: $e'));
    }
  }

  @override
  Future<Result<AccountingYear>> create(String name) async {
    try {
      final existingYears = await _localDataSource.getAll();
      final isFirst = existingYears.isEmpty;
      
      // Check for duplicates
      if (existingYears.any((y) => y.name.toLowerCase() == name.toLowerCase())) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }

      final newYear = AccountingYearModel(
        id: IdGenerator.generateUniqueId(),
        name: name,
        isActive: isFirst,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        isDirty: true,
      );

      await _localDataSource.create(newYear);
      _syncTrigger.requestSync(syncDomain);
      return Success(newYear);
    } catch (e) {
      // In case of SQFLite UNIQUE constraint hit simultaneously
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }
      return Failure(DatabaseFailure('Failed to create accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> rename(String id, String newName) async {
    try {
      final existingYears = await _localDataSource.getAll();
      if (existingYears.any((y) => y.id != id && y.name.toLowerCase() == newName.toLowerCase())) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }

      await _localDataSource.rename(id, newName);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        return const Failure(ValidationFailure('An accounting year with this name already exists.'));
      }
      return Failure(DatabaseFailure('Failed to rename accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> setActive(String id) async {
    try {
      await _localDataSource.setActive(id);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure('Failed to set active accounting year: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final year = await _localDataSource.getById(id);
      if (year == null) {
        return const Failure(ValidationFailure('Accounting year not found.'));
      }

      if (year.isActive) {
        return const Failure(ValidationFailure('Cannot delete the currently active accounting year.'));
      }

      await _localDataSource.delete(id);
      _syncTrigger.requestSync(syncDomain);
      return const Success(null);
    } catch (e) {
      // Catch Foreign Key constraints if invoices are attached
      if (e is DatabaseException && e.toString().contains('FOREIGN KEY constraint failed')) {
        return const Failure(ValidationFailure('Cannot delete this year because it contains invoices.'));
      }
      return Failure(DatabaseFailure('Failed to delete accounting year: $e'));
    }
  }

  @override
  Future<SyncResult> pushChanges(String businessId) async {
    try {
      final dirtyModels = await _localDataSource.getDirtyYears();
      if (dirtyModels.isEmpty) return const SyncResult(skipped: 0);

      final dirtyYears = dirtyModels.map((m) => m as AccountingYear).toList();
      
      await _remoteDataSource.pushYears(businessId, dirtyYears);
      
      final ids = dirtyYears.map((y) => y.id).toList();
      await _localDataSource.updateSyncMetadata(ids, DateTime.now().toUtc());
      
      return SyncResult(uploaded: dirtyYears.length);
    } catch (e, stack) {
      debugPrint('AccountingYear push failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }

  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async {
    try {
      final remoteYears = await _remoteDataSource.pullYears(businessId, lastSyncTime);
      if (remoteYears.isEmpty) return const SyncResult(skipped: 0);

      int downloaded = 0;
      int conflicts = 0;

      for (final remoteYear in remoteYears) {
        final localModel = await _localDataSource.getById(remoteYear.id);
        
        if (localModel == null) {
          await _localDataSource.overwriteYear(AccountingYearModel.fromEntity(remoteYear));
          downloaded++;
        } else {
          final localYear = localModel as AccountingYear;
          
          if (remoteYear.updatedAt.compareTo(localYear.updatedAt) <= 0) {
            continue;
          }

          if (!localYear.isDirty) {
            await _localDataSource.overwriteYear(AccountingYearModel.fromEntity(remoteYear));
            downloaded++;
          } else {
            conflicts++;
            final winningYear = _conflictResolver.resolve(
              localYear,
              remoteYear,
            );
            
            if (winningYear == remoteYear) {
              await _localDataSource.overwriteYear(AccountingYearModel.fromEntity(winningYear));
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
      debugPrint('AccountingYear pull failed: $e\n$stack');
      return const SyncResult(failed: 1);
    }
  }
}
