import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/events/repository_change_publisher.dart';
import 'package:payme/core/events/repository_event.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_priority.dart';
import 'package:payme/core/sync/sync_result.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';
import 'package:payme/presentation/features/accounting_years/controllers/accounting_year_controller.dart';
import 'package:payme/presentation/providers/repository_providers.dart';

class DummyAccountingYearRepository implements AccountingYearRepository, RepositoryChangePublisher {
  final _eventController = StreamController<RepositoryEvent>.broadcast();
  List<AccountingYear> _years = [];

  void setYears(List<AccountingYear> years) {
    _years = years;
  }

  void triggerSyncEvent() {
    _eventController.add(RepositoryEvent(
      type: RepositoryEventType.remoteSynchronization,
      domain: SyncDomain.accountingYears,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  @override
  void dispose() {
    _eventController.close();
  }

  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    return Success(_years.where((y) => !y.isDeleted).toList());
  }

  @override
  SyncDomain get syncDomain => SyncDomain.accountingYears;
  @override
  SyncPriority get syncPriority => SyncPriority.level6AccountingYears;
  @override
  Future<Result<AccountingYear>> create(String name) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear>> delete(String id) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear?>> getById(String id) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear?>> getByName(String name) async => Failure(const DatabaseFailure(''));
  @override
  Future<SyncResult> pullChanges(String businessId, DateTime? lastSyncTime) async => const SyncResult(downloaded: 0);
  @override
  Future<SyncResult> pushChanges(String businessId) async => const SyncResult(uploaded: 0);
  @override
  Future<Result<AccountingYear>> softDelete(String id) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear>> update(AccountingYear year) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear?>> getActive() async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<void>> rename(String id, String newName) async => const Success(null);
  @override
  Future<Result<void>> setActive(String id) async => const Success(null);
}

void main() {
  group('AccountingYearController Sync Regression', () {
    test('invalidates and refetches when repository emits sync event', () async {
      final repo = DummyAccountingYearRepository();
      
      final initialYear = AccountingYear(
        id: 'year1',
        name: '2025',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repo.setYears([initialYear]);

      final container = ProviderContainer(
        overrides: [
          accountingYearRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Read to trigger build() and attach listener
      var years = await container.read(accountingYearControllerProvider.future);
      expect(years.length, 1);
      expect(years.first.name, '2025');

      // Simulate remote insertion
      final newYear = AccountingYear(
        id: 'year2',
        name: '2040',
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repo.setYears([initialYear, newYear]);
      
      // Emit event
      repo.triggerSyncEvent();

      // Give Riverpod a microtask to process the invalidation
      await Future.delayed(Duration.zero);

      // Verify the controller refetched automatically
      years = await container.read(accountingYearControllerProvider.future);
      expect(years.length, 2);
      expect(years.last.name, '2040');

      // Simulate remote soft deletion
      final deletedYear = AccountingYear(
        id: 'year1',
        name: '2025',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: true,
      );
      repo.setYears([deletedYear, newYear]);
      
      // Emit event
      repo.triggerSyncEvent();
      await Future.delayed(Duration.zero);

      // Verify
      years = await container.read(accountingYearControllerProvider.future);
      expect(years.length, 1); // 2025 is deleted
      expect(years.first.name, '2040');
    });
  });
}
