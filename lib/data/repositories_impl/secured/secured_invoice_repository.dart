import '../../../domain/repositories/invoice_repository.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../domain/entities/client_visibility_context.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';
import '../../../core/events/repository_change_publisher.dart';
import '../../../core/events/repository_event.dart';

class SecuredInvoiceRepository implements InvoiceRepository, RepositoryChangePublisher {
  final InvoiceRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredInvoiceRepository(this._inner, this._permissionService, this._currentUser);

  @override
  Stream<RepositoryEvent> watchEvents() {
    if (_inner is RepositoryChangePublisher) {
      return (_inner as RepositoryChangePublisher).watchEvents();
    }
    return const Stream.empty();
  }

  @override
  void dispose() {}

  AppFailure _unauthorized() {
    return const AuthFailure('Unauthorized access to invoice data.');
  }

  @override
  Future<Result<Invoice>> create(Invoice invoice) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesCreate)) {
      return Failure(_unauthorized());
    }

    final securedInvoice = invoice.copyWith(
      createdBy: _currentUser!.user.uid,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.create(securedInvoice);
  }

  @override
  Future<Result<Invoice>> update(Invoice invoice) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesEdit)) {
      return Failure(_unauthorized());
    }

    final existingResult = await _inner.getById(invoice.id);
    if (existingResult is! Success || (existingResult as Success).value == null) {
      return Failure(const DatabaseFailure('Invoice not found.'));
    }
    final existing = (existingResult as Success).value!;

    final securedInvoice = invoice.copyWith(
      createdBy: existing.createdBy,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.update(securedInvoice);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesDelete)) {
      return Failure(_unauthorized());
    }
    return await _inner.delete(id);
  }

  @override
  Future<Result<Invoice?>> getById(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getById(id);
  }

  @override
  Future<Result<List<Invoice>>> getInvoicesForYear(String accountingYearId, {ClientVisibilityContext? visibilityContext}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesView)) {
      return Failure(_unauthorized());
    }
    
    final actualVisibleToUserId = visibilityContext?.visibleToUserId ?? _currentUser!.user.uid;
    
    return await _inner.getInvoicesForYear(
      accountingYearId,
      visibilityContext: ClientVisibilityContext(visibleToUserId: actualVisibleToUserId),
    );
  }

  @override
  Future<Result<List<Invoice>>> getInvoicesForClient(String accountingYearId, String clientId, {ClientVisibilityContext? visibilityContext}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesView)) {
      return Failure(_unauthorized());
    }
    
    final actualVisibleToUserId = visibilityContext?.visibleToUserId ?? _currentUser!.user.uid;
    
    return await _inner.getInvoicesForClient(
      accountingYearId,
      clientId,
      visibilityContext: ClientVisibilityContext(visibleToUserId: actualVisibleToUserId),
    );
  }

  @override
  Future<Result<int>> getHighestInvoiceNumber(String accountingYearId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getHighestInvoiceNumber(accountingYearId);
  }

  @override
  Future<Result<void>> transferInvoicesToClient(String oldClientId, String newClientId, {Object? txn}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesEdit)) {
      return Failure(_unauthorized());
    }
    return await _inner.transferInvoicesToClient(oldClientId, newClientId, txn: txn);
  }

  @override
  Future<Result<void>> deleteAllForClient(String clientId, {Object? txn}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesDelete)) {
      return Failure(_unauthorized());
    }
    return await _inner.deleteAllForClient(clientId, txn: txn);
  }

  @override
  Future<Result<int>> countAllForClient(String clientId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.invoicesView)) {
      return Failure(_unauthorized());
    }
    return await _inner.countAllForClient(clientId);
  }
}
