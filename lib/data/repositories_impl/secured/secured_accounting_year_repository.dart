import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/accounting_year.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../domain/entities/permissions.dart';
import '../../../domain/repositories/accounting_year_repository.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../../../core/events/repository_event.dart';

class SecuredAccountingYearRepository implements AccountingYearRepository, RepositoryChangePublisher {
  final AccountingYearRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredAccountingYearRepository(
    this._inner,
    this._permissionService,
    this._currentUser,
  );

  @override
  Stream<RepositoryEvent> watchEvents() {
    if (_inner is RepositoryChangePublisher) {
      return (_inner as RepositoryChangePublisher).watchEvents();
    }
    return const Stream.empty();
  }

  @override
  void dispose() {}

  bool _canView() {
    return _permissionService.hasPermission(_currentUser, Permissions.accountingYearsView);
  }

  bool _canManage() {
    return _permissionService.hasPermission(_currentUser, Permissions.accountingYearsManage);
  }

  @override
  Future<Result<List<AccountingYear>>> getAll() async {
    if (!_canView()) {
      return Failure(AuthFailure('You do not have permission to view accounting years.'));
    }
    return _inner.getAll();
  }

  @override
  Future<Result<AccountingYear?>> getActive() async {
    if (!_canView()) {
      return Failure(AuthFailure('You do not have permission to view accounting years.'));
    }
    return _inner.getActive();
  }

  @override
  Future<Result<AccountingYear>> create(String name) async {
    if (!_canManage()) {
      return Failure(AuthFailure('You do not have permission to manage accounting years.'));
    }
    return _inner.create(name);
  }

  @override
  Future<Result<void>> rename(String id, String newName) async {
    if (!_canManage()) {
      return Failure(AuthFailure('You do not have permission to manage accounting years.'));
    }
    return _inner.rename(id, newName);
  }

  @override
  Future<Result<void>> setActive(String id) async {
    if (!_canManage()) {
      return Failure(AuthFailure('You do not have permission to manage accounting years.'));
    }
    return _inner.setActive(id);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!_canManage()) {
      return Failure(AuthFailure('You do not have permission to manage accounting years.'));
    }
    return _inner.delete(id);
  }
}
