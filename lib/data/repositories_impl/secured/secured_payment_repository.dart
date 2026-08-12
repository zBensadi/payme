import '../../../domain/repositories/payment_repository.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/current_app_user.dart';
import '../../../domain/entities/client_visibility_context.dart';
import '../../../core/error/result.dart';
import '../../../core/security/permission_service.dart';
import '../../../domain/entities/permissions.dart';
import '../../../core/error/failures.dart';

class SecuredPaymentRepository implements PaymentRepository {
  final PaymentRepository _inner;
  final PermissionService _permissionService;
  final CurrentAppUser? _currentUser;

  SecuredPaymentRepository(this._inner, this._permissionService, this._currentUser);

  AppFailure _unauthorized() {
    return const AuthFailure('Unauthorized access to payment data.');
  }

  @override
  Future<Result<Payment>> create(Payment payment, {List<String>? newAttachmentSourcePaths}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsCreate)) {
      return Failure(_unauthorized());
    }

    final securedPayment = payment.copyWith(
      createdBy: _currentUser!.user.uid,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.create(securedPayment, newAttachmentSourcePaths: newAttachmentSourcePaths);
  }

  @override
  Future<Result<Payment>> update(Payment payment, {List<String>? newAttachmentSourcePaths, List<String>? deletedAttachmentIds}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsEdit)) {
      return Failure(_unauthorized());
    }

    final existingResult = await _inner.getById(payment.id);
    if (existingResult is! Success || (existingResult as Success).value == null) {
      return Failure(const DatabaseFailure('Payment not found.'));
    }
    final existing = (existingResult as Success).value!;

    final securedPayment = payment.copyWith(
      createdBy: existing.createdBy,
      updatedBy: _currentUser!.user.uid,
    );

    return await _inner.update(securedPayment, newAttachmentSourcePaths: newAttachmentSourcePaths, deletedAttachmentIds: deletedAttachmentIds);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsDelete)) {
      return Failure(_unauthorized());
    }
    return await _inner.delete(id);
  }

  @override
  Future<Result<Payment?>> getById(String id) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getById(id);
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice(String invoiceId, {ClientVisibilityContext? visibilityContext}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsView)) {
      return Failure(_unauthorized());
    }
    
    final actualVisibleToUserId = visibilityContext?.visibleToUserId ?? _currentUser!.user.uid;
    
    return await _inner.getPaymentsForInvoice(
      invoiceId,
      visibilityContext: ClientVisibilityContext(visibleToUserId: actualVisibleToUserId),
    );
  }

  @override
  Future<Result<List<Payment>>> getPaymentsByPeriod(String yearId, {DateTime? start, DateTime? end, ClientVisibilityContext? visibilityContext}) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsView)) {
      return Failure(_unauthorized());
    }
    
    final actualVisibleToUserId = visibilityContext?.visibleToUserId ?? _currentUser!.user.uid;
    
    return await _inner.getPaymentsByPeriod(
      yearId,
      start: start,
      end: end,
      visibilityContext: ClientVisibilityContext(visibleToUserId: actualVisibleToUserId),
    );
  }

  @override
  Future<Result<List<String>>> getAttachmentPathsForInvoice(String invoiceId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getAttachmentPathsForInvoice(invoiceId);
  }

  @override
  Future<Result<List<String>>> getAttachmentPathsForYear(String yearId) async {
    if (!_permissionService.hasPermission(_currentUser, Permissions.paymentsView)) {
      return Failure(_unauthorized());
    }
    return await _inner.getAttachmentPathsForYear(yearId);
  }
}
