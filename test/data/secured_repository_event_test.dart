import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:payme/domain/entities/permissions.dart';
import 'package:payme/core/error/result.dart';
import 'package:payme/core/error/failures.dart';
import 'package:payme/core/events/repository_change_publisher.dart';
import 'package:payme/core/events/repository_event.dart';
import 'package:payme/core/sync/sync_domain.dart';
import 'package:payme/core/sync/sync_priority.dart';
import 'package:payme/core/sync/sync_result.dart';
import 'package:payme/core/security/permission_service.dart';
import 'package:payme/domain/entities/current_app_user.dart';
import 'package:payme/domain/entities/app_user.dart';
import 'package:payme/domain/entities/accounting_year.dart';
import 'package:payme/domain/repositories/accounting_year_repository.dart';
import 'package:payme/data/repositories_impl/secured/secured_accounting_year_repository.dart';

class DummyPermissionService implements PermissionService {
  @override
  bool hasPermission(CurrentAppUser? user, Permission permission) {
    return true; // allow all
  }
}

class DummyAccountingYearRepository implements AccountingYearRepository, RepositoryChangePublisher {
  final _eventController = StreamController<RepositoryEvent>.broadcast();

  void triggerEvent() {
    _eventController.add(RepositoryEvent(
      type: RepositoryEventType.localMutation,
      domain: SyncDomain.accountingYear,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  @override
  Stream<RepositoryEvent> watchEvents() => _eventController.stream;

  @override
  void dispose() {
    _eventController.close();
  }

  // Dummy implementations
  @override
  SyncDomain get syncDomain => SyncDomain.accountingYear;
  @override
  SyncPriority get syncPriority => SyncPriority.level1AccountingYear;
  @override
  Future<Result<AccountingYear>> create(String name) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<AccountingYear>> delete(String id) async => Failure(const DatabaseFailure(''));
  @override
  Future<Result<List<AccountingYear>>> getAll() async => Failure(const DatabaseFailure(''));
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
}

void main() {
  group('SecuredAccountingYearRepository Event Propagation', () {
    test('forwards watchEvents from underlying publisher', () async {
      final innerRepo = DummyAccountingYearRepository();
      final permissionService = DummyPermissionService();
      final testUser = CurrentAppUser(
        user: AppUser(
          id: 'test',
          email: 'test@example.com',
          name: 'Test',
          roleId: 'admin',
          businessId: 'bus_1',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        permissions: {Permissions.accountingYearsView},
      );
      
      final securedRepo = SecuredAccountingYearRepository(
        innerRepo,
        permissionService,
        testUser,
      );

      final events = <RepositoryEvent>[];
      final subscription = securedRepo.watchEvents().listen(events.add);

      innerRepo.triggerEvent();

      await Future.delayed(Duration.zero);
      
      expect(events.length, 1);
      expect(events.first.type, RepositoryEventType.localMutation);
      expect(events.first.domain, SyncDomain.accountingYear);

      await subscription.cancel();
    });
  });
}
